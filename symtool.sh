#!/bin/bash 

clear=false;
quiet=false;
help=false;
test=false;
operation=;

folder=$(pwd);
user="david";
group="david";
composer="/usr/local/bin/composer";

args=$(getopt -o "ciuqh" --long "clear,install,update,test,user:,group:,quiet,help" -- "$@");
if [ $? != 0 ]
then
    help=true;
fi;

eval set -- "$args";

while [ "$1" != "" ]
do
    case "$1" in

        '-c' | '--clear')
            clear=true;
            shift;;

        '-i' | '--install')
            operation="install";
            shift;;

        '-u' | '--update')
            operation="update";
            shift;;

        '--test')
            test=true;
            shift;;

        '--user')
            user=$2
            shift 2;;

        '--group')
            group=$2
            shift 2;;

        '-q' | '--quiet')
            quiet=true;
            shift;;

        '-h' | '--help')
            help=true;
            shift;;

        '--')
            shift;
            break;;
    esac;
done;

if [ $quiet == false -o $help == true ]
then
    echo -e "This tool updates the Symfony project assets in development environments."
    echo -e "\033[33mWarning:\033[0m Not for use in production environments!"
fi;

if [ $help == true ]
then
    echo -e "\nUsage: \033[33msymtool [options] [folder(s)] \033[0m"
    echo -e "\t-h, --help\n\t\tShow this help."
    echo -e "\t-q, --quiet\n\t\tQuiet mode. Don't show anything."
    echo -e "\t-c, --clear\n\t\tDelete the cache and web folders before run."
    echo -e "\t-i, --install\n\t\tRun composer install."
    echo -e "\t-u, --update\n\t\tRun composer update."
    echo -e "\t--test\n\t\tRun unit testing."
    echo -e "\t--user USER\n\t\tUser to chown \"cache\" and \"log\" folders. Root only."
    echo -e "\t--group GROUP\n\t\tGroup to chown \"cache\" and \"log\" folders. Root only."
    echo -e ""
    exit 0;
fi;

if [ "$1" == "" ]
then
    eval set -- "$folder";
fi;

pwd=$(pwd);
while [ "$1" != "" ]
do

    # Change dir
    cd "$1" 1> /dev/null 2> /dev/null
    if [ $? != 0 ]
    then
        echo -e "\033[31mError: Invalid folder: \033[0m$1\n";
        exit 1;
    fi;

    # Variables
    path="$(pwd)";
    apppath="${path}/app";
    webpath="${path}/web";

    # The "app" folder must exist.
    if [ ! -d "$apppath" ]
    then
        echo -e "\033[31mError: \033[0m$path\033[31m is not a Symfony project root folder.\033[0m\n";
        exit 1;
    fi;

    # Process start
    if [ $quiet == false ]
    then
        echo -e "Symfony project root folder: \033[33m$path\033[0m"
    fi;

    # Delete the "app/cache" folder if needed
    if [ $clear == true -a -d "$apppath/cache" ]
    then
        rm -rf "$apppath/cache" 1> /dev/null 2> /dev/null
        if [ $? != 0 ]
        then
            echo -e "\033[31mUnable to remove the \033[0m$apppath/cache\033[31m folder.\033[0m\n";
            exit 1;
        fi;
    fi;

    # Create the "app/cache" folder if needed.
    if [ ! -d "$apppath/cache" ]
    then
        mkdir "$apppath/cache" 1> /dev/null 2> /dev/null
        if [ $? != 0 ]
        then
            echo -e "\033[31mError creating \033[0m$apppath/cache\033[31m folder.\033[0m\n";
            exit 1;
        fi;
    fi;

    # Access permisions change of "app/cache" folder
    if [ $(whoami) == "root" ]
    then

        # Chown "app/cache" folder if needed
        chown -R $user:$group $apppath/cache/
        if [ $? != 0 ]
        then
            echo -e "\033[31mError chown failed on \033[0m$apppath/cache\033[31m folder.\033[0m\n";
            exit 1;
        fi;
        
        # Chmod "app/cache" folder if needed
        chmod -R a+rw $apppath/cache/
        if [ $? != 0 ]
        then
            echo -e "\033[31mError chmod failed on \033[0m$apppath/cache\033[31m folder.\033[0m\n";
            exit 1;
        fi;
    fi;

    # Create the "app/logs" folder if needed.
    if [ ! -d "$apppath/logs" ]
    then
        mkdir "$apppath/logs" 1> /dev/null 2> /dev/null
        if [ $? != 0 ]
        then
            echo -e "\033[31mError creating \033[0m$apppath/logs\033[31m folder.\033[0m\n";
            exit 1;
        fi;
    fi;

    # Access permisions change of "app/logs" folder
    if [ $(whoami) == "root" ]
    then

        # Chown "app/logs" folder if needed
        chown -R $user:$group $apppath/logs/
        if [ $? != 0 ]
        then
            echo -e "\033[31mError chown failed on \033[0m$apppath/logs\033[31m folder.\033[0m\n";
            exit 1;
        fi;
        
        # Chmod "app/logs" folder if needed
        chmod -R a+rw $apppath/logs/
        if [ $? != 0 ]
        then
            echo -e "\033[31mError chmod failed on \033[0m$apppath/logs\033[31m folder.\033[0m\n";
            exit 1;
        fi;
    fi;

    # Delete assets in the "web" folders if needed
    if [ $clear == true ]
    then
        rm -rf "$webpath/bundles"       1> /dev/null 2> /dev/null
        rm -rf "$webpath/images"        1> /dev/null 2> /dev/null
        rm -rf "$webpath/image"         1> /dev/null 2> /dev/null
        rm -rf "$webpath/img"           1> /dev/null 2> /dev/null
        rm -rf "$webpath/fonts"         1> /dev/null 2> /dev/null
        rm -rf "$webpath/font"          1> /dev/null 2> /dev/null
        rm -rf "$webpath/css"           1> /dev/null 2> /dev/null
        rm -rf "$webpath/javascript"    1> /dev/null 2> /dev/null
        rm -rf "$webpath/js"            1> /dev/null 2> /dev/null
    fi;

    # Non-quiet mode...
    if [ $quiet == false ]
    then

        # Run composer install or update if needed
        if [ "$operation" == "install" -o "$operation" == "update" ]
        then
            php $composer $operation
            if [ $? != 0 ]
            then
                echo -e "\033[31mError composer $operation failed.\033[0m\n";
                exit 1;
            fi;
        fi;

        # Clear the Symfony cache
        php $apppath/console -e=dev cache:clear
        php $apppath/console -e=prod cache:clear

        # Assets install
        php $apppath/console assets:install $webpath --symlink

        # Assets dump
        php $apppath/console -e=dev assetic:dump
        php $apppath/console -e=prod assetic:dump

    # Quiet mode
    else

        # Run composer install or update if needed
        if [ "$operation" == "install" -o "$operation" == "update" ]
        then
            php $composer $operation 1> /dev/null 2> /dev/null
        fi;
        if [ $? != 0 ]
        then
            echo -e "\033[31mError composer $operation failed.\033[0m\n";
            exit 1;
        fi;

        # Clear the Symfony cache
        php $apppath/console -e=dev cache:clear     1> /dev/null 2> /dev/null
        php $apppath/console -e=prod cache:clear    1> /dev/null 2> /dev/null

        # Assets install
        php $apppath/console assets:install $webpath --symlink  1> /dev/null 2> /dev/null

        # Assets dump
        php $apppath/console -e=dev assetic:dump    1> /dev/null 2> /dev/null
        php $apppath/console -e=prod assetic:dump   1> /dev/null 2> /dev/null
    fi;

    # Run tests if needed
    if [ $test == true ]
    then
        php bin/phpunit -c app
    fi;

    # Final access permisions change
    if [ $(whoami) == "root" ]
    then
        chown -R $user:$group $path/    1> /dev/null 2> /dev/null
        chmod -R a+rw $apppath/cache/   1> /dev/null 2> /dev/null
    fi;

    # Process end
    cd $pwd 1> /dev/null 2> /dev/null
    shift;
done;


