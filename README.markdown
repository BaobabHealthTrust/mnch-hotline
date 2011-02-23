MNCH-Hotline: Maternal Neonatal Child Hotline System
====================================================

Introduction
------------
MNCH-Hotline is a maternal and neonatal child Hotline System. It is a web based application written on Ruby on Rails framework. 
It runs on top of OpenMRS data model (c.f. http://openmrs.org/ and http://wiki.openmrs.org/display/docs/Data+Model).

Getting Started
---------------
In order to setup the system, do the following:

* Clone it (or download a tar-ball) from github:

      git clone git://github.com:BaobabHealthTrust/mnch-hotline.git

* Create a database:

      mysqladmin -u root -p create mnch_hotline

* Create database.yml (from database.yml.example) and configure it according to your system and database setups.
* On the commandline, run the initial_database_setup script from the application's directory:

      script/initial_database_setup.sh ENVIRONMENT SITE

where ENVIRONMENT corresponds to the one(s) you configured in the database.yml and SITE is the name of the site directory as listed in db/data/. If any of the sites does not suite you, use 'defualts' as site name.

Source code
-----------
The latest code can be found at:
    https://github.com/BaobabHealthTrust/mnch-hotline.

Contact the Developers
----------------------
We would be very glad to get some feedback from you:
    developers(at)baobabhealth(dot)org (http://baobabhealth.org/)

![BaobabHealth](http://baobabhealth.org/wp-content/themes/atahualpa34/images/huge-logo.gif)
