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
end
