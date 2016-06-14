%% select file 
[file_nm, temp] = uigetfile(fullfile(dir_nm, '*.tif;*.mat'));
if isstr(temp)
    if temp(end)~=filesep; temp(end+1) = filesep; end 
    dir_nm = temp; 
    save([CNMFE_DIR, filesep, '.dir.mat'],  'dir_nm');
    set(edit_dir, 'string', dir_nm); 
else
    fprintf('no file was selected. STOP!\N');
    return;
end
nam = [dir_nm, file_nm];  % full name of the data file
[~, file_nm, file_type] = fileparts(nam); %#ok<ASGLU>

%% convert data to *.mat file and map it to memory
gui_load_mat; 
set(edit_height, 'string', d1); 
set(edit_width, 'string', d2); 
set(edit_frame, 'string', numFrame); 
neuron_raw = Sources2D('d1',d1,'d2',d2, 'bas_nonneg', 1, ...
    'gSig', 4, 'gSiz', 15);   % dimensions of datasets

sframe = 1; 
eframe = numFrame; 
num2read = eframe-sframe+1; 
set(edit_begin, 'string', 1); 
set(edit_end, 'string', eframe); 
set(edit_total, 'string', num2read); 

%% update file types and file names 
file_type = '.mat'; 
nam = nam_mat; 
set(edit_file, 'string', [file_nm, file_type]); 