provider "google" {
	project     = "${var.project}"
  credentials = "${file("credentials.json")}"
}
