module IssuesControllerPatch
  def self.included(base)
    base.class_eval do
      # Insert overrides here, for example:


      def update
        sla_time_helper = Object.new.extend(SlaTimeHelper)
        change_status = false
        if @issue.project.enabled_modules.map(&:name).include?('redmine_issue_sla') #&& @issue.status_id.to_s != params[:issue][:status_id]
          sla_time_helper.duration_of_ticket(params[:id], params[:issue][:status_id])
          change_status = true if @issue.status_id.to_s != params[:issue][:status_id]
        end
        return unless update_issue_from_params
        @issue.save_attachments(params[:attachments] || (params[:issue] && params[:issue][:uploads]))
        saved = false
        begin
          saved = save_issue_with_child_records
        rescue ActiveRecord::StaleObjectError
          @conflict = true
          if params[:last_journal_id]
            @conflict_journals = @issue.journals_after(params[:last_journal_id]).all
            @conflict_journals.reject!(&:private_notes?) unless User.current.allowed_to?(:view_private_notes, @issue.project)
          end
        end

        if saved
          param_priority = params[:issue][:priority_id]
          active_sla = @issue.project.enabled_modules.map(&:name).include?('redmine_issue_sla')
          p '========== many conditions ======================='
          if active_sla && sla_time_helper.check_sla_hours(@issue) && change_status &&@issue.sla_times.present? && @issue.project.issue_sla_statuses.find_by_issue_status_id(@issue.status_id).sla_timer == 'start'
            dur = @issue.sla_times.last.pre_status_duration
            hh,mm = dur.divmod(60)
            mm =  mm.to_i.to_s.size > 1 ? mm.to_i : "0#{mm.to_i}"
            s = TimeEntry.new(:project_id => @issue.project.id, :issue_id => @issue.id, :hours => "#{hh}.#{mm}", :comments => sla_time_helper.retun_time_entry_msg(@issue.sla_times.last) , :activity_id => 8 , :spent_on => Date.today)
            s.user_id =  @issue.sla_times.last.user_id
            s.save
            p s.errors
          end
          if param_priority.present? && active_sla
            priority = IssuePriority.find(param_priority)
            @issue.update_attributes(:estimated_hours => @issue.project.issue_slas.find_by_priority_id(priority.id).allowed_delay, :priority_id => param_priority)
          end
            render_attachment_warning_if_needed(@issue)
          flash[:notice] = l(:notice_successful_update) unless @issue.current_journal.new_record?

          respond_to do |format|
            format.html { redirect_back_or_default issue_path(@issue) }
            format.api  { render_api_ok }
          end
        else
          respond_to do |format|
            format.html { render :action => 'edit' }
            format.api  { render_validation_errors(@issue) }
          end
        end
      end


    end
  end
end


