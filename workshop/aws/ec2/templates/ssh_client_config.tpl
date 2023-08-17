%{ for index, name in names ~}
Host ${name}
    Hostname ${ips[index]}
    User ubuntu
    IdentityFile ${key}
%{ endfor ~}
