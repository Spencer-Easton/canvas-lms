Beyond Z Canvas LMS
======

How to install:
-----

Follow the instructions from the Canvas wiki <https://github.com/instructure/canvas-lms/wiki/Quick-Start>

* on my box i had to run the i18n thing as  root individually but it should work automatically on other boxes

* I was able to skip a few steps because the ruby for the main platform worked here. If you already have the BZ code running, you should also have ruby and might be able to take a shortcut too.


If you get:
NameError: method `respond_to_missing?' not defined in ActiveRecord::NamedScope::Scope

Find: canvas-lms/config/initializers/rails2.rb:127
and comment that line, uncomment the method below to create the db

You may need to change config/domain.yml

To start the server, run: rails server -p 3001 (a different port is used so it won't conflict with the main application)

If you see:
script/rails:6:in `require': cannot load such file -- rails/commands (LoadError)

Run:
bundle show rails

Then change the line of the error (script/rails:6) to:

require 'PATH_TO_RAILS/lib/commands'

where PATH_TO_RAILS is found in the bundle show command.


My notes while looking at the source
=========

Plugin folders:

canvas-lms/app/views/plugins
canvas-lms/lib/canvas/plugins/

testing is done in the /spec directory.

node.js is apparently used to compile assets

the basic setup is
	users have accounts in the system
	there's courses in the system
	user accounts are tied to courses via roles which grant them access to various parts

	external service login works by getting info from the other service then doing a
	lookup and create a local account as needed to match it and log them in.

	My strategy is to make BZ an OAuth provider and make Canvas understand it, similarly
	to a FB login. It won't be accepted upstream since BZ isn't big like Facebook but the
	way the existing code works is a series of if/else service!

	git should be able to keep our branch straight though.

	Then, hopefully, we can make it automatically and always use this instead of the built in
	login except for admin stuff, but I haven't gotten to that yet...

The advantage of this oauth sso is we can then do cross-domain communication with an authenticated
user - if we do have to iframe the resume app, for instance, we'll know which user is logged in
without needing them to do a separate manual step.


BZ Git branch layout
========

UPSTREAM STABLE
	=> BZ stable - we should never commit to this, it just mirrors upstream stable; it is where we stage changes for upstream PRs
		=> BZ master (merges from staging)
		=> BZ staging
			=> feature branches (will also merge ones from upstream if needed)
		=> feature branches intended to go upstream (branched off stable)


Dev wise, we need to use a different branch:
	* stable matches upstream
	* we branch from stable for a feature that we want to merge up
	* our own stuff is in a BZ branch, which works as our master
	* upstream things that work for us too are merged from the off master branch into our off BZ branch
		(git checkout beyondz; git checkout -b integrate_that_thing_with_us; git merge that_thing)


Production Deploy for BZ
===========

Check out our branch to your local machine and run bundle install. This will install capistrano locally. Also run ssh-agent locally (refer to its instructions for a full install, but generally: run the program, set the environment it spits out, then do ssh-add to add your identity for forwarding). Without the ssh-agent, cap deploy will complain it couldn't log into github from the server.

On the server, we create a user called 'deploy'.

adduser deploy
passwd -l deploy # prohibit regular login
cd ~deploy
mkdir .ssh
chown deploy ssh
chmod .ssh 600
cd .ssh
touch authorized_keys # put in a different key for each individual deployer. Should match what you use for github for easiest access to repo
chown deploy authorized_keys
chmod 600 authorized_keys


Also, in /var/canvas, we will want to make sure it is all set up correctly for our repo:

git remote -v

If it doesn't show beyond-z, fix it with:
git remote set-url origin git@github.com:beyond-z/canvas-lms.git

Also check
git config user.name

If it isn't set, run:

git config user.email 'tech@beyondz.org'
git config user.name 'Beyond Z'

so it doesn't complain about a missing identity when you add a new user.

Lastly, we want to make a restart script that the deploy user can run for automatic apache restarting:

echo 'deploy ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/deploy
chmod 0440 /etc/sudoers.d/deploy



Do that stuff only once. After the server is prepared, just run this locally:

$ bundle exec cap staging deploy:update

from the canvas folder and it should work to update code from our github repo. If you get a "remote disconnect", double check the ssh-agent setup and environment variables.


The rest is just the original Canvas README contents:


Canvas LMS
======

Canvas is a new, open-source LMS by Instructure Inc. It is released under the
AGPLv3 license for use by anyone interested in learning more about or using
learning management systems.

[Please see our main wiki page for more information](http://github.com/instructure/canvas-lms/wiki)

Installation
=======

Detailed instructions for installation and configuration of Canvas are provided
on our wiki.

 * [Quick Start](http://github.com/instructure/canvas-lms/wiki/Quick-Start)
 * [Production Start](http://github.com/instructure/canvas-lms/wiki/Production-Start)
