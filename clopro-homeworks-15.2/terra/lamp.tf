resource "yandex_iam_service_account" "lamp-group-acc" {
    name      = "lamp-group-acc"
}

resource "yandex_resourcemanager_folder_iam_member" "lamp-group-editor" {
    folder_id = var.folder_id
    role      = "editor"
    member    = "serviceAccount:${yandex_iam_service_account.lamp-group-acc.id}"
}

resource "yandex_compute_instance_group" "lamp-instance-group" {
  name                = "lamp-instance-group"
  service_account_id  = "${yandex_iam_service_account.lamp-group-acc.id}"
  deletion_protection = false
  instance_template {
    
    resources {
      memory = 2
      cores  = 2
    }

    boot_disk {
      initialize_params {
        image_id = "fd827b91d99psvq5fjit"
      }
    }

    network_interface {
      network_id = yandex_vpc_network.network-study.id
      subnet_ids = [yandex_vpc_subnet.public.id]
      nat        = true
    }

    metadata = {
      user-data  = <<EOF
#!/bin/bash
echo '<html><img src="http://${yandex_storage_bucket.static-pic.bucket_domain_name}/pic"/></html>' > /var/www/html/index.html
EOF
      ssh-keys = "ubuntu:ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAJkjyC8jM6WyALVI5h/cBOLtxO/OsxSU6Matw+HHefF"
    }

    scheduling_policy {
      preemptible = true
    }
  }

  scale_policy {
    fixed_scale {
      size = 2
    }
  }

  allocation_policy {
    zones = [var.default_zone]
  }

  deploy_policy {
    max_unavailable = 2
    max_creating    = 2
    max_expansion   = 2
    max_deleting    = 2
  }

  health_check {
    http_options {
      port    = 80
      path    = "/"
    }
  }

  load_balancer {
    target_group_name = "some-group"
  }
}