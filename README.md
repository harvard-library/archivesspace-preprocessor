# ArchivesSpace Preprocessing System

## Project Description

The ArchivesSpace Preprocessing system is a system intended to process EAD files and apply changes to them to allow for successful ingest into [ArchivesSpace](https://github.com/archivesspace/archivesspace)

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

## Fixes

Fixes are corrections for individual issues defined in a schematron file.  They're loaded from `system/fixes` on Rails initialization.  An individual fix is defined by the fix_for function, which takes an identifier for the issue it fixes, an optional array of dependencies (identifiers of other fixes that must be run before this fix), and a block containing the actual code to be run.

There's no hard requirements around nameing, but local practice at Harvard has been to put each fix in its own file, named after the identifier.

Within a fix, the following variable is defined:

| Variable      |                                                                    |
|---------------|--------------------------------------------------------------------|
| *@xml*        | A Nokogiri::XML::Document representing the finding aid             |

### Example Fixes

``` ruby
# Fix for "issue-1"
fix_for "issue-1" do
  @xml.at_xpath('/ead')['level'] = "addLevelToEAD"
end

# Fix for "issue-2"
fix_for "issue-2", depends_on: ["issue-1"] do
  ead = @xml.at_xpath('/ead')
  ead['level'] += "_stuff_added_to_level"
end
```

## Contributors

* Dave Mayo: http://github.com/pobocks

## License and Copyright

2015 President and Fellows of Harvard College
