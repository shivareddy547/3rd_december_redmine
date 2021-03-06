module RedmineIssueSla
  module Infectors
    module Project
      module ClassMethods; end
  
      module InstanceMethods; end

      def self.included(receiver)
        receiver.extend(ClassMethods)
        receiver.send(:include, InstanceMethods)
        receiver.class_eval do
          unloadable
          
          has_many :issue_slas, :class_name => 'IssueSla', :foreign_key => 'project_id'
          has_many :issue_sla_statuses, :class_name => 'IssueSlaStatus', :foreign_key => 'project_id'
          has_one :sla_working_day, :class_name => 'SlaWorkingDay', :foreign_key => 'project_id'
          has_one :response_sla, :class_name => 'ResponseSla', :foreign_key => 'project_id'
        end
      end
      
    end
  end
end