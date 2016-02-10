class Report
  # NOTE: Maybe move this to Run?
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
      pluck('code','substr(issues.message, 0, 120)', 'COUNT(concrete_issues.id)')
  end
end
