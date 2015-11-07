@test "monit is installed and in the path" {
  which monit
}

@test "initscript is installed" {
  test -f /etc/init.d/fake-web
}

@test "fake environment.sh is installed" {
  test -f /var/www/fake/shared/environment.sh
}

@test "fake environment.sh contains the right settings" {
  grep 8080 /var/www/fake/shared/environment.sh
}

@test "fake thin is running" {
  pgrep -f fake.*thin
}

@test "fakier environment.sh is installed" {
  test -f /var/www/fakier/shared/environment.sh
}

@test "fakier environment.sh contains the right settings" {
  grep 8002 /var/www/fakier/shared/environment.sh
}

@test "fakier thin is running" {
  pgrep -f fakier.*thin
}
