
software
.......................................................

linux
apache + mod_auth_pam + mod_fastcgi
tetex + cstex
perl
ImageMagick
postgresql + Pg
Mail::Sendmail
wget


packages (ubuntu dapper drake)
.......................................................

libapache2-mod-auth-pam
libapache2-mod-auth-sys-group
libapache2-mod-fastcgi
libcgi-fast-perl
libfcgi-perl
libmail-sendmail-perl
tetex-base
tetex-bin
tetex-extra
tex-common


database
.......................................................

initialize:
    su postgres
    /usr/bin/initdb --pgdata=/var/lib/postgresql --locale=cs_CZ.ISO8859-2

psql template1:
	create database isss;
	create user isss password '*******';

pg_hba.conf:
	local   isss    isss    password

restore data:
	pg_restore -d isss isss.000.tar  -U isss

backup data:
	pg_dump -Ft -b -U isss isss > isss.061003.tar
