function root = projectRoot()

current_file = mfilename('fullpath');

functions_folder = fileparts(current_file);

matlab_folder = fileparts(functions_folder);

root = fileparts(matlab_folder);

end