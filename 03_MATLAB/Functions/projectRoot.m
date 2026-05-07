function root = projectRoot()

root = fileparts(...
    matlab.project.currentProject().RootFolder);

end