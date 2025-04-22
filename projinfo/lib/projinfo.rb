require "open3"
require "etc"
require "json"


class Projinfo
  def initialize()
  end

  def main
    if ENV["OOD_DASHBOARD_TITLE"]=="Alvis OnDemand"
       resource = "Alvis"
    else
       resource = "Vera"
    end

    cmd = "/usr/local/bin/projinfo -r #{resource} --json"
    data, stderr_str, status = Open3.capture3(cmd)
    projects = JSON.parse(data)
    target = Etc.getpwuid.name
    user_projects = projects.select do |project|
      project["users"].any? { |user| user["username"] == target }
      if (project["queue"].eql? "alvis")
        project["unit_desc"] = "GPU-hours"
      else
        project["unit_desc"] = "core-hours"
      end
    end
    return user_projects
  end
end
