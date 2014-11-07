RedmineApp::Application.routes.draw do
  put '/projects/:project_id/issue_slas' => 'issue_slas#update'
  post '/projects/:project_id/issue_slas' => 'issue_slas#update'
  get '/projects/:project_id/issue_slas' => 'issue_slas#update'
  get 'issue_slas/add_response_sla', :to => 'issue_slas#add_response_sla'

end