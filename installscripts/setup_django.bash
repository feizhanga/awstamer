#!/usr/bin/env bash
###############################################################################
# Purpose:  One cmd script to install, config, django, postgres, gunicorn, nginx,
#           Python Virtualenv environment, all pyhton package installed by pip into ViPyEnv
#
# Author: fei.zhang@ga.gov.au
# Date: 2015-06-02
# Usage: Redhat-CentOS
# edit the first few lines according to your VM IP then run it as a non-root user, who has sudo privilege
#
# Todo: Deploy a real Apps into a new AWS ec2 instance at creation
# Todo: translate into Puppert/Ansible/Docker
# Todo: further modulized and refactored
###############################################################################
###############################################################################

# User Variables (edit these)
FqdnameOrIpAddress='hostname.compute.amazonaws.com'  #please edit this according to your VM fqdn or IP

PROJECTS_DIR=/opt/django2  #where the djangos projects will be created

DJANGO_PROJECT_NAME='demoproj2' # name of your django project

POSTGRES_DB_NAME='demodb2' # name of the database that your django project will use

##--------------------------------------------------------------------------------
# nothing needs to be changed below this line
##--------------------------------------------------------------------------------
# BEGIN SCRIPT

WHOAMI=`whoami`  # unix user: 

sudo mkdir -p $PROJECTS_DIR

sudo chown -R ${WHOAMI} $PROJECTS_DIR

ls -l $PROJECTS_DIR
# exit

if [ "${WHOAMI}" == "root" ]; then
	echo "Don't run this script as root."
	exit
fi

# output
myprint() { echo "$@" 1>&2; }

control_c() {
  myprint "Ctrl+c pressed. Exiting... ***\n"
  cleanup
  exit $?
}

# Install and Configure PostgreSQL
setup_postgres() {

    #  Install PostgreSQL
    sudo yum -y install postgresql93*

    sudo  /etc/init.d/postgresql93 initdb
    sudo chkconfig  postgresql93 on
    sudo  /etc/init.d/postgresql93 start

    #create user $WHOAMI
    sudo su postgres -c "createuser  $WHOAMI"

    #alter database mydb owner to ubuntu;
    sudo su postgres -c "createdb \"$POSTGRES_DB_NAME\" -O  $WHOAMI"

}

setup_django(){

    virtualenv $PROJECTS_DIR/ViPyEnv
    source $PROJECTS_DIR/ViPyEnv/bin/activate

    myprint "pip Install Django and DB drivers"
    #sudo
    pip install django
    pip install psycopg2

    cd $PROJECTS_DIR/

    django-admin.py startproject $DJANGO_PROJECT_NAME

# massage setting.py
    cd $PROJECTS_DIR/$DJANGO_PROJECT_NAME/$DJANGO_PROJECT_NAME
    mv settings.py settings.py.backup # backup the original settings

    SETTINGS_PY=`cat settings.py.backup`
    TARGET="'ENGINE': 'django.db.backends.sqlite3'"
    NEW_STUFF="'ENGINE': 'django.db.backends.postgresql_psycopg2'"

    SETTINGS_PY="${SETTINGS_PY/$TARGET/$NEW_STUFF}"

    NLT=$'\n\t'

    TARGET="'NAME': os.path.join(BASE_DIR, 'db.sqlite3'),"
    #NEW_STUFF="'NAME': '$POSTGRES_DB_NAME',${NLT}'USER':'postgres',${NLT}'PASSWORD':'postgres',${NLT}'HOST':'',${NLT}'PORT':'',${NLT}";
    NEW_STUFF="'NAME': '$POSTGRES_DB_NAME',${NLT}";

    SETTINGS_PY="${SETTINGS_PY/$TARGET/$NEW_STUFF}"

    echo "$SETTINGS_PY" > settings.py

    cd $PROJECTS_DIR/$DJANGO_PROJECT_NAME
    python manage.py migrate
    retval=$?

    if [ $retval -ne 0 ]; then
        myprint " Failed db migration !"
    else
    myprint " create a superuser"
    # Not again
        python manage.py createsuperuser
    fi
 }

# Install Gunicorn
setup_gunicorn(){
    myprint "Install Gunicorn"

    virtualenv $PROJECTS_DIR/ViPyEnv
    source $PROJECTS_DIR/ViPyEnv/bin/activate

    #sudo
    pip install gunicorn

    # Configure Gunicorn
    myprint "Configure Gunicorn"

    echo "
command = '/usr/local/bin/gunicorn'
pythonpath = '$PROJECTS_DIR/$DJANGO_PROJECT_NAME'
bind = '$FqdnameOrIpAddress:8001'  #OR  '0.0.0.0:8001'
workers = 1
# user = 'nobody'
    " > $PROJECTS_DIR/$DJANGO_PROJECT_NAME/$DJANGO_PROJECT_NAME/gunicorn_config.py
    # workers = 3" > $PROJECTS_DIR/$DJANGO_PROJECT_NAME/$DJANGO_PROJECT_NAME/gunicorn_config.py

    # Start the server
    myprint "Starting gunicorn django..."

    cd $PROJECTS_DIR/$DJANGO_PROJECT_NAME/

    # to run the gunicorn (as nobody user) sudo gunicorn
    gunicorn -c $DJANGO_PROJECT_NAME/gunicorn_config.py $DJANGO_PROJECT_NAME.wsgi &

   echo "Testing at:  http://$FqdnameOrIpAddress:8001/admin "
}

setup_nginx() { # worked for Ubut 

    #Install NGINX
    myprint "Install NGINX"
    sudo yum -y install nginx

    myprint " Configure NGINX"

    mkdir $PROJECTS_DIR/static/

    #this may fail for virtualenv
    sudo cp -r /usr/local/lib/python2.7/site-packages/django/contrib/admin/static/admin/ $PROJECTS_DIR/static/

    sudo echo "
    server {
        server_name localhost;
        access_log off;
        location /static/admin/ {
            alias $PROJECTS_DIR/static/admin/;
        }
        location /static/ {
            alias $PROJECTS_DIR/static/;
        }
        location / {
                proxy_pass http://127.0.0.1:8001;
                proxy_set_header X-Forwarded-Host \$server_name;
                proxy_set_header X-Real-IP \$remote_addr;
                add_header P3P 'CP=\"ALL DSP COR PSAa PSDa OUR NOR ONL UNI COM NAV\"';
        }
    }" >  /etc/nginx/sites-available/$DJANGO_PROJECT_NAME

    sudo ln -s /etc/nginx/sites-available/$DJANGO_PROJECT_NAME /etc/nginx/sites-enabled/$DJANGO_PROJECT_NAME

    sudo rm /etc/nginx/sites-enabled/default

    sudo service nginx restart

}

setup_modwsgi(){
# This will bundle apache/httpd with mod-wsgi to have a full functional website.
MOD_WSIG_USER=$WHOAMI

#libs required by modwsgi
sudo yum install httpd.x86_64
sudo yum install httpd-devel.x86_64

virtualenv $PROJECTS_DIR/ViPyEnv
source $PROJECTS_DIR/ViPyEnv/bin/activate
pip install mod-wsgi

# massage setting.py to use mod-wsgi server
    cd $PROJECTS_DIR/$DJANGO_PROJECT_NAME/$DJANGO_PROJECT_NAME

    SETTINGS_PY=`cat settings.py`

    TARGET="'django.contrib.staticfiles',"
    NEW_STUFF="'django.contrib.staticfiles', 'mod_wsgi.server',";

    SETTINGS_PY="${SETTINGS_PY/$TARGET/$NEW_STUFF}"

    echo "$SETTINGS_PY" > settings.py
    echo "STATIC_ROOT = '$PROJECTS_DIR/$DJANGO_PROJECT_NAME/static/'" >> settings.py

    cd  $PROJECTS_DIR/$DJANGO_PROJECT_NAME
    python manage.py collectstatic
  
    python manage.py runmodwsgi --setup-only --port=8888 --user $MOD_WSIG_USER --group $MOD_WSIG_USER --server-root=mod_wsgi-express-8888
    mod_wsgi-express-8888/apachectl start


    # not work sudo  $PROJECTS_DIR/ViPyEnv/bin/python manage.py runmodwsgi --setup-only --port=8888 --user $MOD_WSIG_USER --group $MOD_WSIG_USER --server-root=/etc/mod-wsgi-express8888

    sudo  /etc/mod-wsgi-express8888/apachectl start

echo "please check and edit /etc/mod-wsgi-express8888/apachectl"

}
#In the Beginning, .....
############################################################################
# trap keyboard interrupt (control-c)
trap control_c SIGINT

# activate sudo for this session
sudo -v  #validate
if [ $? -eq 0 ] # sudo myprint "This script needs sudo access..."; then
then
	echo "sudo access validated ......."
else
    echo "sudo problem: make sure the running user has sudo privilege"
	exit 1
fi

myprint "Update and install Packages"

sudo yum -y update
sudo yum -y install gcc*  # gcc is needed by psycopg2 etc
sudo yum -y upgrade
sudo yum -y install python27-devel.x86_64
sudo yum -y install python-pip
sudo pip install --upgrade pip
sudo ln -sf /usr/local/bin/pip /usr/bin/pip

# Install and Create Virtualenv
sudo yum -y install python27-virtualenv.noarch

# call shell functions
setup_postgres

setup_django

#setup_gunicorn
#setup_nginx

#OR mod-wsgi
setup_modwsgi

######################################################################
# The end

