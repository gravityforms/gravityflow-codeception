#!/bin/bash

# Allows WP CLI to run with the right permissions.
wp-su() {
    sudo -E -u www-data wp "$@"
}

install_gravity_forms() {
	rm -rf /wp-core/wp-content/plugins/gravityforms

		if [ $GF_BRANCH ]; then
			branch=$GF_BRANCH
    else
    	branch='master'
    fi

    echo "Grabbing Gravity Forms $branch branch"

    git clone -b $branch --single-branch https://$GITHUB_TOKEN@github.com/gravityforms/gravityforms.git /wp-core/wp-content/plugins/gravityforms

    cd /wp-core/wp-content/plugins/gravityforms

    npm install

		bash ./bin/link-monorepo $GITHUB_TOKEN

		npm run dist
}

install_gravity_flow() {
    rm -rf /wp-core/wp-content/plugins/gravityflow

    echo "Grabbing the latest development master of Gravity Flow."

    git clone -b master --single-branch https://$GITHUB_TOKEN@github.com/gravityforms/gravityflow.git /wp-core/wp-content/plugins/gravityflow
    cd /wp-core/wp-content/plugins/gravityflow
    npm install && \
    npm run release
}

# Clean up from previous tests
rm -rf /wp-core/wp-content/uploads/gravity_forms


# Make sure permissions are correct.
echo 'Setting permissions'
cd /wp-core
chmod 755 wp-content
chown www-data:www-data wp-content
chown www-data:www-data wp-content/plugins

export WP_CLI_CACHE_DIR=/wp-core/.wp-cli/cache

# Make sure the database is up and running.
while ! mysqladmin ping -hmysql --silent; do

    echo 'Waiting for the database'
    sleep 1

done

echo 'The database is ready'

# Make sure WordPress is installed.
if ! $(wp-su core is-installed); then

    echo "Installing WordPress"

    # The development version of Gravity Flow requires SCRIPT_DEBUG and GF_SCRIPT_DEBUG
    wp-su core config --dbhost=mysql --dbname=wordpress --dbuser=root --dbpass=wordpress --extra-php="define( 'SCRIPT_DEBUG', true ); define( 'GF_SCRIPT_DEBUG', true );" --force

    wp-su core install --url=wordpress --title=tests --admin_user=admin --admin_email=test@test.com

    install_gravity_forms
    install_gravity_flow
else

    if [[ ${NO_CACHE_GRAVITY_FORMS} == '1' ]]; then
        install_gravity_forms
    fi

    if [[ ${NO_CACHE_GRAVITY_FLOW} == '1' ]]; then
        install_gravity_flow
    fi
fi


cd /project

exec "codecept" "$@"
