"""
Capture leaderboard snapshots for all active seasons.

Usage:
    python manage.py snapshot_leaderboard
    python manage.py snapshot_leaderboard --season-id 3

Intended to be run on a cron (weekly/monthly) so each active season
holds a fresh frozen ranking of the whole school.
"""

from django.core.management.base import BaseCommand
from main_app.models import LeaderboardSeason
from main_app.hod_views import _capture_season_snapshot


class Command(BaseCommand):
    help = "Snapshot the current full-school ranking into each active leaderboard season."

    def add_arguments(self, parser):
        parser.add_argument(
            "--season-id",
            type=int,
            default=None,
            help="Snapshot only the given season (otherwise: all active seasons).",
        )

    def handle(self, *args, **opts):
        if opts["season_id"]:
            seasons = LeaderboardSeason.objects.filter(id=opts["season_id"])
        else:
            seasons = LeaderboardSeason.objects.filter(is_active=True)

        if not seasons.exists():
            self.stdout.write(self.style.WARNING("No matching seasons found."))
            return

        total = 0
        for season in seasons:
            count = _capture_season_snapshot(season)
            total += count
            self.stdout.write(self.style.SUCCESS(f"  ✓ {season.name}: {count} snapshots"))

        self.stdout.write(
            self.style.SUCCESS(
                f"Done. {total} snapshots written across {seasons.count()} season(s)."
            )
        )
