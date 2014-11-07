module SlaTimeHelper

  def duration_of_ticket(issue_id, issue_status)

    p '===============================prammmmm'
    p = Issue.find(issue_id).project
    s  = IssueStatus.find(issue_status)
    issue = Issue.find issue_id
    sla_id = p.issue_sla_statuses.find_by_issue_status_id(s.id)

    if check_sla_hours(issue)
      p '===== new condition ====='
      current_status = issue.project.issue_sla_statuses.find_by_issue_status_id(issue.status_id)
      p '======== over ========='
      if  current_status.present? && current_status.sla_timer == 'start'
        # issue.project.issue_sla_statuses.find_by_issue_status_id(issue.status_id).sla_timer == 'start'
        issue.sla_times.create(:issue_sla_status_id => sla_id.id,:user_id => issue.assigned_to_id,  :old_status_id =>( issue.sla_times.last.id rescue nil), :pre_status_duration => 0 )
        issue.sla_times.first.update_attributes(:old_status_id => issue.sla_times.first.id) if issue.sla_times.count == 1
        # if issue.sla_times.last.old_status.created_at.to_date == issue.sla_times.last.created_at.to_date
        #   duration =  ((issue.sla_times.last.created_at.to_time - issue.sla_times.last.old_status.created_at.to_time)/ 60).round
        # else
        #   time_hm = issue.sla_times.last.created_at.localtime.strftime('%H.%M')
        #   c_hm = (f_hr * 60) + f_min
        #   t_hh = time_hm.split(/\./).first.to_i
        #   t_mm = time_hm.split(/\./).last.to_i
        #   t_hm = (t_hh * 60) + t_mm
        #   duration = t_hm - c_hm
        # end
        duration =  return_sla_duration(issue, current_status)
        issue.sla_times.last.update_attributes(:pre_status_duration => duration)
      # else
      #   issue.sla_times.last.update_attributes(:pre_status_duration => 0)
      end
    end
  end

  def return_sla_duration(issue, current_status)
    f_hr = issue.project.sla_working_day.start_at.split(/\./).first.to_i
    f_min = issue.project.sla_working_day.start_at.split(/\./).last.to_i
    e_hr = issue.project.sla_working_day.end_at.split(/\./).first.to_i
    e_min = issue.project.sla_working_day.end_at.split(/\./).last.to_i
p 'ha am here =================='
    p issue.sla_times.count==1, current_status

    if issue.sla_times.count == 1 && current_status.sla_timer == 'start'
      p '-----raise'
      duration =  ((issue.sla_times.last.created_at.to_time - issue.created_on.to_time )/ 60).round
    p '----------------------dur-------------------'
      p duration
    elsif issue.sla_times.last.old_status.created_at.to_date == issue.sla_times.last.created_at.to_date
      duration =  ((issue.sla_times.last.created_at.to_time - issue.sla_times.last.old_status.created_at.to_time)/ 60).round
    else
      time_hm = issue.sla_times.last.created_at.localtime.strftime('%H.%M')
      c_hm = (f_hr * 60) + f_min
      t_hh = time_hm.split(/\./).first.to_i
      t_mm = time_hm.split(/\./).last.to_i
      t_hm = (t_hh * 60) + t_mm
      duration = t_hm - c_hm
    end
    duration
  end

  def retun_time_entry_msg(slatime)
    new_status = slatime.issue_sla_status.issue_status.name
    pre_status = slatime.old_status.issue_sla_status.issue_status.name
    pre_status = pre_status == new_status ? 'New' : pre_status
    "Status was changed from #{pre_status} to #{new_status}"
  end

  def check_sla_hours(issue)
    f_hr = issue.project.sla_working_day.start_at.split(/\./).first.to_i
    f_min = issue.project.sla_working_day.start_at.split(/\./).last.to_i
    e_hr = issue.project.sla_working_day.end_at.split(/\./).first.to_i
    e_min = issue.project.sla_working_day.end_at.split(/\./).last.to_i
    t = Time.now
    Time.local(t.year, t.month, t.day, f_hr, f_min) <= Time.now && Time.local(t.year, t.month, t.day, e_hr, e_min) >= Time.now
  end

  def update_time_entry_end_of_day
   Project.all.collect do |project|
     if project.enabled_modules.map(&:name).include?('redmine_issue_sla') && project.sla_working_day.present?
       e_hr = project.sla_working_day.end_at.split(/\./).first.to_i
       e_min = project.sla_working_day.end_at.split(/\./).last.to_i
       project.issues.collect do |issue|
        if today_holiday?(issue)
          sla = issue.sla_times.last
          p '--------------- find me ================='
           if sla.present? && sla.created_at.to_date == Date.today && sla.issue_sla_status.present? && sla.issue_sla_status.sla_timer =='start'
             duration = ((Time.now.change({ hour: e_hr, min: e_min, sec: 00 }) - issue.sla_times.last.created_at.localtime)/60).to_i
             issue.sla_times.create(:issue_sla_status_id => sla.issue_sla_status_id,:user_id => issue.assigned_to_id,  :old_status_id =>( issue.sla_times.last.id rescue nil), :pre_status_duration => duration )
             issue.sla_times.first.update_attributes(:old_status_id => issue.sla_times.first.id) if issue.sla_times.count == 1
             dur = issue.sla_times.last.pre_status_duration
             p ' previous dur ==========='
             p dur
             hh,mm = dur.divmod(60)
             mm =  mm.to_i.to_s.size > 1 ? mm.to_i : "0#{mm.to_i}"
             rec = TimeEntry.new(:project_id => project.id, :issue_id => issue.id, :hours => "#{hh}.#{mm}", :comments => retun_time_entry_msg(sla) , :activity_id => 8 , :spent_on => Date.today)
             rec.user_id =  issue.sla_times.last.user_id
             rec.save
             p '================= background job ==================='
             # p rec
           end
        end
       end
     end
   end


  end

  def sla_time_count(issue)

    f_hr = issue.project.sla_working_day.start_at.split(/\./).first.to_i
    f_min = issue.project.sla_working_day.start_at.split(/\./).last.to_i
      if issue.project.enabled_modules.map(&:name).include?('redmine_issue_sla')
        total = 0
        if issue.estimated_hours.present?
          hour, minute = issue.estimated_hours.to_s.split(/\./).first, issue.estimated_hours.to_s.split(/\./).last
          minute = minute.size == 1 ? minute.to_i*10 : minute
          minute = (minute.to_i * 60) / 100
          estimated_hours =  issue.estimated_hours.present? ? issue.estimated_hours : 0.0
          first = ((estimated_hours.to_s.split(/\./).first.to_i * 60) + minute.to_i)
          total = first - issue.sla_times.sum('pre_status_duration').to_i
        end
        current_status = issue.project.issue_sla_statuses.find_by_issue_status_id(issue.status_id).sla_timer

        if current_status == 'start' && today_holiday?(issue)
          if issue.sla_times.count == 0 && current_status == 'start'
            spare_time =  ((Time.now.localtime - issue.created_on.to_time.localtime )/ 60).round
          elsif issue.sla_times.last.created_at.to_date == Date.today
            spare_time =  ((Time.now.localtime - issue.sla_times.last.created_at.localtime) / 60).to_i
          else
            time_hm = Time.now.strftime('%H.%M')
            c_hm = (f_hr * 60) + f_min
            t_hh = time_hm.split(/\./).first.to_i
            t_mm = time_hm.split(/\./).last.to_i
            t_hm = (t_hh * 60) + t_mm
            spare_time = t_hm - c_hm
          end

          test =   total - spare_time.to_i
          hh,mm = test.abs.divmod(60)
          @sym = test > -1 ? '' : '- '
        else
          @sym = total > -1 ? '' : '- '
          hh,mm = total.abs.divmod(60)
        end
        min = mm.to_s.size == 1 ? "0#{mm}" : mm
        total_dur = "#{@sym}#{hh}.#{min}"
      else
        total_dur =   issue.estimated_hours
      end
        return total_dur
  end

  def today_holiday?(issue)
    holiday = Date.today
    if holiday.wday == 0 && issue.project.sla_working_day.sun == false
      false
    elsif holiday.wday == 1 && issue.project.sla_working_day.mon == false
      false
    elsif holiday.wday == 2 && issue.project.sla_working_day.tue == false
      false
    elsif holiday.wday == 3 && issue.project.sla_working_day.wed == false
      false
    elsif holiday.wday == 4 && issue.project.sla_working_day.thu == false
      false
    elsif holiday.wday == 5 && issue.project.sla_working_day.fri == false
      false
    elsif holiday.wday == 6 && issue.project.sla_working_day.sun == false
      false
    elsif Setting.plugin_redmine_wktime['wktime_public_holiday'].present? && Setting.plugin_redmine_wktime['wktime_public_holiday'].include?(holiday.to_date.strftime('%Y-%m-%d').to_s)
      false
    else
      true
    end

  end

end