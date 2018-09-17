data_set_path = '/media/lmans/Data/mapillary-vistas-dataset_public_v1.0';
lane_path = '/media/lmans/Data/mapillary-for-lane-detection/lane-segs';
training_path = fullfile(data_set_path,'training');
im_path = fullfile(training_path,'images');
label_path = fullfile(training_path,'labels');

ims = dir(fullfile(im_path,'*.jpg'));
labels = dir(fullfile(label_path,'*.png'));
lane_files = dir(fullfile(lane_path,'*.png'));

config = jsondecode(fileread(fullfile(data_set_path,'config.json')));
cmap = uint8([config.labels(:).color].');
figure;
for i = 1:length(lane_files)
    fprintf('image %d/%d -- ',i,length(ims));
    im = imread(fullfile(im_path,[lane_files(i).name(1:end-3) 'jpg']));
    label = imread(fullfile(label_path,lane_files(i).name));
    lanes = imread(fullfile(lane_path,lane_files(i).name));
    
	subplot(1,3,1);imshow(im_with_overlays(im,{lanes == 1}));
	subplot(1,3,2);imshow(label,cmap);
	subplot(1,3,3);imshow(im_with_overlays(im,{lanes,label == 24 | label == 2}));
    
    drawnow
end
