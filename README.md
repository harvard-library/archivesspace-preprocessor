# ArchivesSpace Preprocessing System

## Project Description

The ArchivesSpace Preprocessing system is a system intended to process EAD files and apply changes to them to allow for successful ingest into [ArchivesSpace](https://github.com/archivesspace/archivesspace)

## System Requirements

### General

* A JVM capable of running JRuby 9.0.5.0+
* JRuby 9.0.5.0+ (targets MRI 2.2)
* Bundler

This system is tested and run in production in the following environment:

| Components             |                      |
|------------------------|----------------------|
| *Operating System*     | OSX, Linux (RHEL 6.7)|
| *Database*             | PostgreSQL 9.x       |
| *Web Server*           | Apache 2.x           |
| *Application Server*   | Passenger            |
| *Ruby version manager* | RVM                  |

### Development/Test

In order to run the test suite, you'll need to install [PhantomJS](http://phantomjs.org)

## Application Set-up Steps

1. Run bundle install. You will probably have to install OS-vendor supplied libraries to satisfy some gem install requirements.
2. Create the database (`rake db:create`) and run `rake db:schema:load`, after modifying "config/database.yml" to suit your environment.
3. Create a .env file or otherwise set up the following environment variables:

  ```
  SECRET_KEY_BASE=ThirtyPlusCharStringOfRandomnessGottenFromRakeSecretMaybe # Required in RAILS_ENV=production
  TIME_ZONE='Eastern Time (US & Canada)'                                    # Defaults to UTC if not provided
  ```

## Fixes

Fixes are corrections for individual issues defined in a schematron file.  They're loaded from `system/fixes` on Rails initialization (start up or restart).  An individual fix is defined by the fix_for function, which takes an identifier for the issue it fixes, an optional keyword argument `depends_on` with an array of dependencies (identifiers of other fixes that must be run before this fix), and a block containing the actual code to be run.

Note that YOU are responsible for not making circular dependencies - don't make fix-1 and fix-2 both depend on each other, for example, or things will break.

There's no hard requirements around naming, but local practice at Harvard has been to put each fix in its own file, named after the identifier.

Within a fix, the following variable is defined:

| Variable      |                                                                    |
|---------------|--------------------------------------------------------------------|
| *@xml*        | A Nokogiri::XML::Document representing the finding aid             |

This variable is implicitly returned at the end of the fix block, any changes made will be reflected in the final finding aid.

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

### Error handling in Fixes

If an error occurs and the fix cannot successfully complete, you can raise a `Fixes::Failure` exception.  The processor will catch this, and discard the results of this fix, but still attempt to make apply other relevant fixes to the finding aid.  As of now, you shouldn't do this in a fix that has other fixes which depend on it; results are not guaranteed to be good.

## Usage Instructions

ArchivesSpace Preprocessor is a Rails application, but in many ways, it's more useful to think of it as a command-line preprocessing script.  At the end of the day, the primary workflow is:

``` sh
# Add a schematron to the preprocessor from the command line.
bundle exec rake aspace:ingest:schematron FILE=/path/to/my/schematronfile.xml

# Run processor over a set of EADs
bundle exec rake aspace:process:analyze_and_fix EADS=/path/to/my/EADs NAME=meaningful_name
```

Note that you don't need to add a new schematron every time - only when there's a change to the schematron you're using.

And after a while (currently about one hour per 6000 EAD files), the output EAD files (and a zipped collection of same) are located in `$APP_ROOT/public/output/$DB_ID_OF_RUN`.  The resulting files (and, in future, analytics) are then available via the web interface.

## Developer/Database User Notes

For reference, here's an automatically generated ER diagram of the application's models: [model_diagram.png](model_diagram.png). Entries without arrows are classes not backed by database tables; the "dotted line" entry for DigestedFile represents a module included by the various file classes.

A short description of how the tool functions, using model names, would look something like this:

    A Run of the processor consists of the Checker being used to run a Schematron over one or more FindingAidVersions, producing ConcreteIssues. If the Run is intended to produce amended EAD as output, each FindingAidVersion is then processed, and depending on what Issues it has, Fixes are run over it in an order determined by dependencies amongst them.

There are quite a few models here, but the objects tracked by the system are:

### Schematrons

[Schematron](http://www.schematron.com/) is an ISO/IEC standard language for making assertions about XML documents.  A Schematron object in the ArchivesSpace Preprocessor is the primary source for errors you know about in your finding aid.  Operations generally use the last Schematron document ingested by the tool, but former Schematron documents are kept around for reference purposes.  Schematrons are described by a combination of:

1. A record in the database.
2. A file on disk in the `/public/schematrons/` directory.

Schematrons are uniquely identified by a SHA-256 hash of their content.  Any change to contents is considered to be a completely separate Schematron.

### Issues (and ConcreteIssues)

Issues are a representation of problems described in the Schematron.  A variety of identifying info is pulled from the Schematron file, but the main field to be aware of is the `identifier` field.  This is a unique ID provided by the creator of the schematron document, taken from the diagnostics attributes of the %lt;assert&gt;s within the schematron document.

ConcreteIssues are representations of Issues actually found in particular FindingAidVersions, and include location and other context info.

### FindingAidVersions (and FindingAids

FindingAidVersions represent particular versions of an EAD file; i.e. the exact content of an EAD file at some point in time.  FindingAids are more or

## Contributors

* Dave Mayo: http://github.com/pobocks

## License and Copyright

2015 President and Fellows of Harvard College
