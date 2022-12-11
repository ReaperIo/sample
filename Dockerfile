FROM perl
WORKDIR /opt/my_app
COPY . .
RUN cpanm --installdeps -n .
EXPOSE 3000

RUN chmod 0755 /opt/my_app/daemon.pl

CMD ./script/my_app prefork