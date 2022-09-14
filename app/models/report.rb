require 'set'
# Various reports, aggregated here for convenience
class Report
  # Returns a report of issues found per repository
  #
  # @param run [Run] the Run being reported over
  # @return [Hash<Hash<String>>] the report
  def self.issues_per_repo(run)
    Repository.
      joins(finding_aids: {
              finding_aid_versions: {
                concrete_issues: [:issue,:run]
              }
            }).
      where(runs: {id: run.id}).
      group('repositories.id', 'issues.id').
      order('code, substr').
      pluck('code', Arel.sql('substr(issues.message, 0, 120)'), 'COUNT(concrete_issues.id)').
      group_by {|el| el[1]}.
      map do |k, v|
        [k, v.map {|el| [el[0], el[2]]}.to_h] # Drop message from vals, then hashify
      end.to_h
  end

  def self.manual_issues(run)
    manual_issues = Set.new(run.schematron.issues.where("identifier NOT IN (?)", Fixes.to_h.keys).pluck('identifier'))
    Run.
      joins(finding_aid_versions: [
              {concrete_issues: :issue},
              :finding_aid
            ]).
      where({'runs.id' => run.id, 'issues.identifier' => manual_issues}).
      group('eadid', 'issues.id', Arel.sql("issues.identifier || ' - ' || issues.message")).
      order('eadid', 'issues.id').
      pluck('eadid', Arel.sql("issues.identifier || ' - ' || issues.message"), Arel.sql('array_agg(DISTINCT concrete_issues.line_number)'))

    # Todo: put this into some kind of usable data format and display it somewhere?

  end

end
