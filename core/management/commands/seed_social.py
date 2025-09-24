import os
from django.core.management.base import BaseCommand, CommandError
from django.contrib.sites.models import Site
from allauth.socialaccount.models import SocialApp


class Command(BaseCommand):
    help = "Seed (create/update) django-allauth SocialApp entries from environment variables"

    def handle(self, *args, **options):
        site_id_str = os.environ.get("SITE_ID", "1").strip()
        try:
            site_id = int(site_id_str)
        except ValueError as e:
            raise CommandError(f"SITE_ID must be an integer, got: {site_id_str}") from e

        try:
            site = Site.objects.get(id=site_id)
        except Site.DoesNotExist as e:
            raise CommandError(f"Site with id={site_id} does not exist. Create it in /admin or via migrations.") from e

        providers = [
            {
                "provider": "google",
                "name": "Google",
                "client_id": os.environ.get("GOOGLE_CLIENT_ID", "").strip(),
                "secret": os.environ.get("GOOGLE_CLIENT_SECRET", "").strip(),
            },
            {
                "provider": "facebook",
                "name": "Facebook",
                "client_id": os.environ.get("FACEBOOK_APP_ID", "").strip(),
                "secret": os.environ.get("FACEBOOK_APP_SECRET", "").strip(),
            },
        ]

        for p in providers:
            if not p["client_id"] or not p["secret"]:
                self.stdout.write(self.style.WARNING(f"Skipping {p['provider']} (missing env credentials)"))
                continue

            app, created = SocialApp.objects.get_or_create(
                provider=p["provider"],
                defaults={"name": p["name"], "client_id": p["client_id"], "secret": p["secret"]},
            )

            if created:
                self.stdout.write(self.style.SUCCESS(f"Created {p['provider']} SocialApp"))
            else:
                changed = False
                if app.name != p["name"]:
                    app.name = p["name"]
                    changed = True
                if app.client_id != p["client_id"]:
                    app.client_id = p["client_id"]
                    changed = True
                if app.secret != p["secret"]:
                    app.secret = p["secret"]
                    changed = True
                if changed:
                    app.save()
                    self.stdout.write(self.style.SUCCESS(f"Updated {p['provider']} SocialApp"))
                else:
                    self.stdout.write(f"No changes for {p['provider']}")

            # Ensure site linkage
            if site not in app.sites.all():
                app.sites.add(site)
                self.stdout.write(self.style.SUCCESS(f"Linked site {site_id} to {p['provider']}"))
