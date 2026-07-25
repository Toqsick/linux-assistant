import 'dart:io';

import 'package:flutter/material.dart';
import 'package:linux_assistant/enums/distros.dart';
import 'package:linux_assistant/l10n/app_localizations.dart';
import 'package:linux_assistant/layouts/hermes_tokens.dart';
import 'package:linux_assistant/layouts/mint_y.dart';
import 'package:linux_assistant/layouts/security_check/security_finding.dart';
import 'package:linux_assistant/services/linux.dart';
import 'package:linux_assistant/services/main_search_loader.dart';
import 'package:linux_assistant/widgets/hermes/hermes_badge.dart';
import 'package:linux_assistant/widgets/hermes/hermes_card.dart';

/// Standalone security page, reached from search.
class SecurityCheckOverview extends StatelessWidget {
  const SecurityCheckOverview({super.key});

  @override
  Widget build(BuildContext context) {
    return MintYPage(
      title: AppLocalizations.of(context)!.securityCheck,
      customContentElement: const Expanded(child: SecurityCheckContent()),
      bottom: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          MintYButtonNavigate(
            route: const MainSearchLoader(),
            text: Text(AppLocalizations.of(context)!.backToSearch,
                style: MintY.heading4),
            color: Colors.white,
          ),
        ],
      ),
    );
  }
}

/// The security findings, read-only.
///
/// This area inspects and explains; it never changes the system. Where an
/// earlier version offered a "Fix" button that installed a firewall or altered
/// home directory permissions, it now shows the command and leaves the decision
/// — and the execution — with the user.
class SecurityCheckContent extends StatefulWidget {
  const SecurityCheckContent({super.key});

  @override
  State<SecurityCheckContent> createState() => _SecurityCheckContentState();
}

class _SecurityCheckContentState extends State<SecurityCheckContent> {
  late Future<String> _checkerOutput = _runChecker();

  static Future<String> _runChecker() {
    final home = "--home=${Platform.environment['HOME']}";
    final distro = Linux.currentenvironment.distribution;

    String script;
    if (distro == DISTROS.OPENSUSE) {
      script = "check_security_opensuse.py";
    } else if (distro == DISTROS.FEDORA) {
      script = "check_security_fedora.py";
    } else if ([DISTROS.ARCH, DISTROS.MANJARO, DISTROS.ENDEAVOUR]
        .contains(distro)) {
      script = "check_security_arch.py";
    } else {
      script = "check_security.py";
    }

    return Linux.runPythonScript(script,
        root: true, arguments: [home], getErrorMessages: true);
  }

  void _reload() {
    setState(() => _checkerOutput = _runChecker());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return FutureBuilder<String>(
      future: _checkerOutput,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return MintYLoadingPage(text: l10n.analysingSystemSecurity);
        }

        final output = snapshot.data!;
        if (!output.contains("#!script ran successfully.")) {
          return _rootRequired(context);
        }

        return ListView(
          padding: const EdgeInsets.all(HermesTokens.space4),
          children: [
            _readOnlyBanner(context),
            const SizedBox(height: HermesTokens.space4),
            for (final finding in _buildFindings(context, output))
              SecurityFindingTile(finding: finding),
          ],
        );
      },
    );
  }

  Widget _readOnlyBanner(BuildContext context) {
    final t = HermesTokens.of(context);
    final l10n = AppLocalizations.of(context)!;

    return HermesCard(
      spineColor: t.accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              HermesBadge(
                icon: Icons.visibility_outlined,
                tone: HermesTone.accent,
                text: l10n.readOnly,
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _reload,
                icon: const Icon(Icons.refresh, size: 14),
                label: Text(l10n.reload),
              ),
            ],
          ),
          const SizedBox(height: HermesTokens.space2),
          Text(
            l10n.securityReadOnlyIntro,
            style: TextStyle(color: t.muted, fontSize: 12, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _rootRequired(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(HermesTokens.space4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.securityCheckFailedBecauseNoRoot,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: HermesTokens.space4),
            TextButton.icon(
              onPressed: _reload,
              icon: const Icon(Icons.refresh, size: 16),
              label: Text(l10n.retry),
            ),
          ],
        ),
      ),
    );
  }

  /// Turns the checker's line-prefixed output into prioritized findings.
  List<SecurityFinding> _buildFindings(BuildContext context, String output) {
    final l10n = AppLocalizations.of(context)!;
    final lines = output.split("\n");

    final additionalSources = <String>[];
    bool yayInstalled = false;
    int availableUpdatePackages = 0;
    bool homeFolderSecure = true;
    bool firewallNotInstalled = false;
    bool firewallRunning = true;
    bool sshRunning = false;
    bool xrdpRunning = false;
    bool fail2banRunning = true;

    for (final line in lines) {
      if (line.startsWith("additionalsource:")) {
        additionalSources.add(line.replaceFirst("additionalsource: ", ""));
      } else if (line.startsWith("yayinstalled")) {
        yayInstalled = true;
      } else if (line.startsWith("upgradeablepackage:")) {
        availableUpdatePackages++;
      } else if (line.startsWith("homefoldernotsecure:")) {
        homeFolderSecure = false;
      } else if (line.startsWith("firewallinactive")) {
        firewallRunning = false;
      } else if (line.startsWith("nofirewall")) {
        firewallNotInstalled = true;
      } else if (line.startsWith("xrdprunning")) {
        xrdpRunning = true;
      } else if (line.startsWith("sshrunning")) {
        sshRunning = true;
      } else if (line.startsWith("fail2bannotrunning")) {
        fail2banRunning = false;
      }
    }

    final findings = <SecurityFinding>[];

    // --- Network ---
    if (firewallNotInstalled) {
      findings.add(SecurityFinding(
        severity: FindingSeverity.high,
        title: l10n.noFirewallRecognized,
        why: l10n.whyFirewall,
        command: "sudo ufw status verbose",
      ));
    } else if (!firewallRunning) {
      findings.add(SecurityFinding(
        severity: FindingSeverity.high,
        title: l10n.firewallIsInactive,
        why: l10n.whyFirewall,
        command: "sudo ufw status verbose",
      ));
    } else {
      findings.add(SecurityFinding(
        severity: FindingSeverity.ok,
        title: l10n.firewallIsRunning,
      ));
    }

    if (xrdpRunning) {
      findings.add(SecurityFinding(
        severity: FindingSeverity.high,
        title: l10n.xrdpRunningOnYourComputer,
        why: l10n.whyXrdp,
        command: "systemctl status xrdp",
      ));
    }

    if (sshRunning) {
      findings.add(SecurityFinding(
        severity:
            fail2banRunning ? FindingSeverity.info : FindingSeverity.high,
        title: l10n.sshFoundOnYourComputer,
        why: l10n.whySsh,
        command: "sudo ss -tlnp | grep ':22'",
      ));
      if (!fail2banRunning) {
        findings.add(SecurityFinding(
          severity: FindingSeverity.high,
          title: l10n.noFail2BanFound,
          why: l10n.whyFail2ban,
          command: "systemctl is-active fail2ban",
        ));
      }
    }

    // --- Home folder ---
    if (!homeFolderSecure) {
      findings.add(SecurityFinding(
        severity: FindingSeverity.medium,
        title: l10n.homeFolderRightsNotOkay,
        why: l10n.whyHomeFolder,
        command: "ls -ld ~",
      ));
    } else {
      findings.add(SecurityFinding(
        severity: FindingSeverity.ok,
        title: l10n.homeFolderRightsOkay,
      ));
    }

    // --- Updates ---
    if (availableUpdatePackages > 0) {
      findings.add(SecurityFinding(
        severity: FindingSeverity.medium,
        title: "$availableUpdatePackages ${l10n.xPackagesShouldBeUpdated}",
        why: l10n.whyUpdates,
        command: _updateListCommand(),
      ));
    } else {
      findings.add(SecurityFinding(
        severity: FindingSeverity.ok,
        title: l10n.systemIsUpToDate,
      ));
    }

    // --- Software sources ---
    if (additionalSources.isNotEmpty) {
      findings.add(SecurityFinding(
        severity: FindingSeverity.medium,
        title: l10n.additionalSoftwareSourcesDetected,
        why: l10n.whySources,
        details: additionalSources,
        command: _sourcesCommand(),
      ));
    } else if (!yayInstalled) {
      findings.add(SecurityFinding(
        severity: FindingSeverity.ok,
        title: l10n.noAdditionalSoftwareSourcesFound,
      ));
    }

    if (yayInstalled) {
      findings.add(SecurityFinding(
        severity: FindingSeverity.medium,
        title: l10n.yayInstalled,
        why: l10n.whyYay,
        command: "pacman -Qi yay",
      ));
    }

    // Most severe first, so the important lines are never below the fold.
    findings.sort((a, b) => a.severity.index.compareTo(b.severity.index));
    return findings;
  }

  static String _updateListCommand() {
    switch (Linux.currentenvironment.distribution) {
      case DISTROS.FEDORA:
        return "dnf check-update";
      case DISTROS.OPENSUSE:
        return "zypper list-updates";
      case DISTROS.ARCH:
      case DISTROS.MANJARO:
      case DISTROS.ENDEAVOUR:
        return "checkupdates";
      default:
        return "apt list --upgradable";
    }
  }

  static String _sourcesCommand() {
    switch (Linux.currentenvironment.distribution) {
      case DISTROS.FEDORA:
        return "dnf repolist enabled";
      case DISTROS.OPENSUSE:
        return "zypper repos";
      case DISTROS.ARCH:
      case DISTROS.MANJARO:
      case DISTROS.ENDEAVOUR:
        return "grep -H '^\\[' /etc/pacman.conf";
      default:
        return "ls -l /etc/apt/sources.list.d/";
    }
  }
}
