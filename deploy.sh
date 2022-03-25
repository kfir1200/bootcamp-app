#!/bin/bash

#this function explain how to use this script 
usage()
{
    echo "those flag's are mandatory:
    
          -u - OKTA_ORG_URL
          -i - OKTA_CLIENT_ID
          -s - OKTA_CLIENT_SECRET
          -h - POSTGRES_HOST_IP
          -p - DB_PASSWORD 
    
          those flag's are optional:

          -n - POSTGRES_USER_NAME, if not provided the default username is: postgres
          -d - POSTGRES_DATABASE, if not provided the default database  is: postgres
          -o - POSTGRES_PORT, if not provided the default port is: 5432

        for example:

        ./deploy.sh -u {OKTA_ORG_URL} -i {OKTA_CLIENT_ID} -s {OKTA_CLIENT_SECRET} -h {DB_HOST_IP} -p {DB_PASSWORD}";exit 1
     
}
#this method gets the flag's and the argument from the user 
while getopts ":u:i:s:h:p:n:d:o" opt; do
    case "${opt}" in
        u)
            okta_url=${OPTARG}
            ;;
        i)
            okta_id=${OPTARG}
            ;;
        s)
            okta_sercret=${OPTARG}
            ;;
        h)
            db_ip=${OPTARG}
            ;;

        p) db_pass=${OPTARG}
            ;;
        n) db_user_name=${OPTARG}
            ;;
        d) db_name=${OPTARG}
            ;;
        o) db_port=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))


# this function validates if the mandatory argument provided, and set optional flags to default if the user dosen't provided them
validate()
{
    if([[ -z "${okta_url}" ]] || [[ -z "${okta_id}" ]] || [[ -z "${okta_sercret}" ]] || [[ -z "${db_ip}" ]] || [[ -z "${db_pass}" ]]); then
        usage
    fi

    if( [[ -z "${db_user_name}" ]]); then
        db_user_name=${OPTARG:-postgres}
    fi

    if( [[ -z "${db_name}" ]]); then
        db_name=${OPTARG:-postgres}
    fi

    if( [[ -z "${db_port}" ]]); then
        db_port=${OPTARG:-5432}
    fi
    
}

# this function install all the dependencies for the application
installation()
{
    sudo apt update
    sudo apt -y upgrade
    curl -sL https://deb.nodesource.com/setup_14.x | sudo -E bash -
    sudo apt -y install nodejs
    cd bootcamp-app
    sudo npm install dotenv
    sudo npm install nodemon
    sudo npm install pm2 -g
    npm run install
}
# this function creates the .env file according to the parameter the user provides
create_env_file()
{
    ip_address=$(curl https://ipinfo.io/ip)
    echo "# Host configuration
      PORT=8080
      HOST=0.0.0.0
      NODE_ENV=development
      HOST_URL=http://$ip_address:8080
      COOKIE_ENCRYPT_PWD=superAwesomePasswordStringThatIsAtLeast32CharactersLong!

    # Okta configuration
      OKTA_ORG_URL=$okta_url
      OKTA_CLIENT_ID=$okta_id
      OKTA_CLIENT_SECRET=$okta_sercret

    # Postgres configuration
      PGHOST=$db_ip
      PGUSERNAME=$db_user_name
      PGDATABASE=$db_name
      PGPASSWORD=$db_pass
      PGPORT=$db_port" > .env
      
}
#this function deploy the application
deploy()
{
    npm run initdb
    sudo pm2 start npm -- run dev
    sudo pm2 save
    sudo pm2 startup  
    clear
}


validate
installation
create_env_file
deploy


