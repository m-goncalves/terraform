 #!/bin/bash
 cat > index.html <<EOF
 <h1> hello, World!<h1>
 <p> DB address: ${db_address} </p>
 <p> DB port:${db_port}</p>
EOF

nohup busybox httpd -f -p ${server_port} &

# "<<-EOF" ... "EOF" is used to provide multi-line string.
# In this case the string must be indeted: (<<-).
# user_data = <<-EOF
#                 #!/bin/bash
#                 echo "hello, World!"> index.html
#                 echo "${data.terraform_remote_state.db.outputs.address}" >> index.html
#                 echo "${data.terraform_remote_state.db.outputs.port}" >> index.html
#                 nohup busybox test-httpd -f -p ${var.server_port} &
#                 EOF