# Archivesspace Preprocessing System

## Project Description

The Archivesspace Preprocessing system is a system intended to process EAD files and apply changes to them to allow for successful ingest into [Archivesspace](https://github.com/archivesspace/archivesspace)

## System Requirements

### General

* A JVM capable of running JRuby 9.0.0.0
* JRuby 9.0.0.0 (targets MRI 2.2)
* Bundler

This system is tested and run in production in the following environment:

| Components             |                      |
|------------------------|----------------------|
| *Operating System*     | OSX, Linux (RHEL 6.7)|
| *Database*             | PostgreSQL 9.x       |
| *Web Server*           | Apache 2.x           |
| *Application Server*   | Passenger            |
| *Ruby version manager* | RVM

### Development/Test

In order to run the test suite, you'll need to install [PhantomJS](http://phantomjs.org)

## Application Set-up Steps

1. Run bundle install. You will probably have to install OS-vendor supplied libraries to satisfy some gem install requirements.
2. Create the database and run `rake db:schema:load`, after modifying "config/database.yml" to suit your environment.

## Contributors

* Dave Mayo: http://github.com/pobocks

## License and Copyright

2015 President and Fellows of Harvard College
