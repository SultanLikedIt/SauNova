from backend.api.claude import HarviaAPI

client = HarviaAPI(username="harviahackathon2025@gmail.com", password="junction25!")
device = client.devices.get_device_by_serial("2513005304")