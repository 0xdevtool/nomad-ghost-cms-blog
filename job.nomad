job "blog" {
  region = "global"
  datacenters = [
    "DC0",
  ]
  type = "service"
  group "svc" {
    count = 1

    restart {
      attempts = 5
      delay    = "30s"
    }

    volume "ghost-content" {
      type      = "host"
      source    = "ghost-content"
      read_only = false
    }

    volume "mysql-data" {
      type      = "host"
      source    = "mysql-data"
      read_only = false
    }

    task "ghostcms" {
      driver = "docker"

      env = {
        "url"                            = "https://dev-blog.nikoder.dev"
        "database__client"               = "mysql"
        "database__connection__host"     = "mysql-server"
        "database__connection__user"     = "root"
        "database__connection__password" = "changeme"
        "database__connection__database" = "devblog"
      }

      volume_mount {
        volume      = "ghost-content"
        destination = "/var/lib/ghost/content"
        read_only   = false
      }

      config {
        image = "arm64v8/ghost:alpine"
        port_map {
          http = 2368
        }
      }

      resources {
        cpu    = 500
        memory = 1024
        network {
          port "http" {}
        }
      }

      service {
        name = "app-gui"
        port = "http"
      }
    }

    task "mysql-server" {
      driver = "docker"

      env = {
        "MYSQL_ROOT_PASSWORD" = "changeme"
      }

      volume_mount {
        volume      = "mysql-data"
        destination = "/var/lib/mysql"
        read_only   = false
      }

      config {
        image = "arm64v8/mysql"
        port_map {
          db = 3306
        }
      }

      resources {
        cpu    = 500
        memory = 1024
        network {
          port "db" {}
        }
      }

      service {
        name = "mysql-server"
        port = "db"

        check {
          type     = "tcp"
          interval = "10s"
          timeout  = "2s"
        }
      }
    }
  }
}
