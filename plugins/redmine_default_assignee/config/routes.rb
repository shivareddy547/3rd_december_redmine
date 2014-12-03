# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html
match '/redmine_rejected_locked_reports/index', :to => 'redmine_rejected_locked_reports#index', :via => [:get, :post]
match '/redmine_rejected_locked_reports/result', :to => 'redmine_rejected_locked_reports#result', :via => [:get, :post]
