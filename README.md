# ArchivesSpace Preprocessing System

## Project Description

The ArchivesSpace Preprocessing system processes EAD files and applies changes (Fixes) to them to allow for successful ingest into [ArchivesSpace](https://github.com/archivesspace/archivesspace)

## System Requirements

### General

* Unix-like system
* A JVM capable of running JRuby 9.0.5.0+
* JRuby 9.0.5.0+ (targets MRI 2.2)
* Bundler

This system is tested and run in production in the following environment:

| Components               |                      |
|--------------------------|----------------------|
| **Operating System**     | OSX, Linux (RHEL 6.7)|
| **Database**             | PostgreSQL 9.x       |
| **Web Server**           | Apache 2.x           |
| **Application Server**   | Passenger            |
| **Ruby version manager** | RVM                  |



### Development/Test

In order to run the test suite, you'll need to install [PhantomJS](http://phantomjs.org)

Developer documentation, generated via Yard, is available [here](http://harvard-library.github.io/archivesspace-preprocessor/).

## Application Set-up Steps

1. Run bundle install. You will probably have to install OS-vendor supplied libraries to satisfy some gem install requirements.
2. Create a `config/database.yml` to suit your environment (example file provided as [config/database.yml.example](config/database.yml.example)).
3. Create the database (`bundle exec rake db:create`)
4. Set up the database (`bundle exec rake db:schema:load`)
5. Create a .env file or otherwise set up the following environment variables:

  ```
  SECRET_KEY_BASE=ThirtyPlusCharStringOfRandomnessGottenFromRakeSecretMaybe # Required in RAILS_ENV=production
  TIME_ZONE='Eastern Time (US & Canada)'                                    # Defaults to UTC if not provided
  ```

6. Add a schematron file to the application

  ```sh
  bundle exec rake aspace:ingest:schematron FILE=/path/to/my/schematronfile.xml
  ```

7. Add [Fixes](#fixes) to application (Harvard's set live [here](http://github.com/harvard-library/aspace-processor-fixes)) by copying them into the `system/fixes` directory.

## Usage Instructions

Although ArchivesSpace Preprocessor is a Rails application, in many ways, it's more useful to think of it as a command-line preprocessing script.  At the end of the day, the primary workflow is:

```sh
# Add a schematron to the preprocessor from the command line.
bundle exec rake aspace:ingest:schematron FILE=/path/to/my/schematronfile.xml

# Populate the fixes directory with fixes
cp ~/fixes_what_I_wrote/* system/fixes/

# Run processor over a set of EADs
bundle exec rake aspace:process:analyze_and_fix EADS=/path/to/my/EADs NAME=meaningful_name
```

Note that you don't need to add a new Schematron file every time - only when there's a change to the Schematron you're using.

And after a while (currently about one hour per 6000 EAD files), the output EAD files (and a zipped collection of same) are located in `$APP_ROOT/public/output/$DB_ID_OF_RUN`.  The resulting files (and, in future, analytics) are then available via the web interface.

There is currently no concept of user privileges in the application.  All web-based functionality is read-only, so there should not security concerns from exposing the web interface.  However, if you have sensitive information contained in your Finding Aids, you will need to control access to the tool as a whole.

## Developer/Database User Notes

For reference, here's an automatically generated ER diagram of the application's models: [model_diagram.png](model_diagram.png). Entries without arrows are classes not backed by database tables; the "dotted line" entry for `DigestedFile` represents a module included by the various file registry classes.

A short description of how the tool functions, using model names, would look something like this:

    A Run of the processor consists of the Checker being used to run a Schematron over one or more FindingAidVersions, producing ConcreteIssues. If the Run is intended to produce amended EAD as output, each FindingAidVersion is then processed, and depending on what Issues it has, Fixes are run over it in an order determined by dependencies amongst them.  Fixes applied are tracked in the database in the form of ProcessingEvents.

There are quite a few models here, but the objects tracked by the system are:

### Schematrons

[Schematron](http://www.schematron.com/) is an ISO/IEC standard language for making assertions about XML documents.  A `Schematron` in the ArchivesSpace Preprocessor is the primary source for errors you know about in your finding aid.  Operations generally use the `Schematron` representing the last Schematron document ingested by the tool, but former `Schematrons` are kept around for reference purposes.  `Schematrons` are described by a combination of:

1. A record in the database.
2. A file on disk in the `/public/schematrons/` directory.

`Schematrons` are uniquely identified by a SHA-256 digest of their content.  Any change to contents is considered to be a completely different `Schematron`.

### Issues (and ConcreteIssues)

`Issues` are a representation of problems described in a `Schematron`.  A variety of contextual information is parsed out of from the Schematron file and present in the database, but the main field to be aware of is the `identifier` field.  This is a unique ID provided by the creator of the Schematron document, taken from the `diagnostics` attribute of the `<assert>`s within the schematron document.

`ConcreteIssues` are representations of `Issues` actually found in particular `FindingAidVersions`, and include location and other context info about the specific instance of said `Issue`.

### FindingAidVersions (and FindingAids)

`FindingAidVersions` represent particular versions of an EAD file as input to the system; i.e. the exact content of an EAD file at some point in time. They are represented by a combination of:

1. A record in the database.
2. A file on disk in the `/public/finding_aids` directory.

`FindingAidVersions` are uniquely identified by a SHA-256 digest of their content.  Any change to contents is considered to be a completely separate `FindingAidVersion`.

Note: `FindingAidVersions` are only created to represent EADs *input to the system*.  *Output* EAD files are only represented on disk, they are not represented in the database.

`FindingAids` represent all versions of an EAD that have existed with the same `<eadid>` value.  They're primarily used in the UI, to enable looking at an EAD as it changes over time.


#### Fixes

`Fixes` are corrections for individual issues defined in a schematron file.  They're loaded from `system/fixes` on Rails initialization (start up or restart).  An individual `Fix` is defined by the `fix_for` function, which takes an identifier for the issue it fixes, an optional keyword argument `depends_on` with an array of dependencies (identifiers of other `Fixes` that must be run before this `Fix`), and a block containing the actual code to be run.

A `Fix` is expected to correct ALL instances of a problem in an EAD file - tracking of `Fix` application is done per file, not per instance of issue in file.

Note that YOU are responsible for not making circular dependencies - don't make fix-1 and fix-2 both depend on each other, for example, or things will break.

There's no hard requirements around naming, but local practice at Harvard has been to put each `Fix` in its own file, named after the identifier.

Within a fix, the following variable is defined:

| Variable        |                                                                    |
|-----------------|--------------------------------------------------------------------|
| **@xml**        | A Nokogiri::XML::Document representing the finding aid             |

Changes should be made directly to it, using the Nokogiri API ([suggested entry point to docs](http://www.nokogiri.org/tutorials/modifying_an_html_xml_document.html)).  This variable is implicitly returned at the end of the fix block. Any changes made will be passed on to the next fix, and reflected in the final finding aid.

If a fix is marked as "preflight", it will be run non-conditionally on EVERY finding aid, after Schematron checking but before other processing. Currently, changes made by preflights are NOT tracked; BE CAREFUL, and make as little use of them as possible!

#### Runs

`Runs` are the top level grouping of objects in the app.  A `Run` represents a collection of all the objects and information produced by running the tool over a set of `FindingAidVersions` with a particular `Schematron` and set of `Fixes`, producing a particular set of `ConcreteIssues`, `ProcessingEvents`, and output EADs (which, again, are associated via filesystem naming convention, rather than in the database).

#### ProcessingEvents

For each `Fix` that's attempted on a `FindingAidVersion`, a `ProcessingEvent` is generated, to be used in reporting.

#### Example Fixes

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

# Preflight fix
fix_for "preflight-1", preflight: true do
  @xml.at_xpath('//extent').each do |ex|
    ex.content = ex.content.strip
  end
end
```

#### Error handling in Fixes

If the code within the fix determines that it cannot be applied successfully, or you want to handle any errors thrown gracefully, you can raise a `Fixes::Failure` exception.  The processor will catch this, and discard the results of this fix, but still attempt to make apply other relevant fixes to the finding aid.  As of now, you shouldn't do this in a fix that has other fixes which depend on it; results are not guaranteed to be good.

For example:

``` ruby
fix_for "issue-1"
  ead = @xml.at_path('/ead')
  if ead.nil?
    # This can't POSSIBLY work, better give up
    raise Fixes::Failure
  end
  ead['level'] = "addLevelToEAD"
end
```



## Contributors

* Dave Mayo: http://github.com/pobocks **(Primary Contact)**


* Bobbi Fox: http://github.com/bobbi-SMR
* Michael Vandermillen: http://github.com/michael-lts

## License and Copyright

2015 President and Fellows of Harvard College
