addpath('/home/lmans/Documents/Code/external_libraries/jsonlab-1.5/jsonlab-1.5')

data_set_path = '/media/disk2/lmans/Data/mapillary-vistas-dataset_public_v1.0';
training_path = fullfile(data_set_path,'training');
im_path = fullfile(training_path,'images');
label_path = fullfile(training_path,'labels');

ims = dir(fullfile(im_path,'*.jpg'));
labels = dir(fullfile(label_path,'*.png'));

config = loadjson(fileread(fullfile(data_set_path,'config.json')));
cmap = zeros(length(config.labels),3,'uint8');
for i = 1:length(config.labels)
    cmap(i,:) = uint8([config.labels{i}.color]);
end
figure;
% for i = 1:length(ims)
%     im = imread(fullfile(im_path,ims(i).name));
%     disp(size(im))
%     label = imread(fullfile(label_path,labels(i).name));
%     
%     subplot(1,2,1);imshow(im);
%     subplot(1,2,2);imshow(label,cmap);
%     
%     
%     drawnow
% end

for i = 1:length(ims)
    im = imread(fullfile(im_path,ims(i).name));
    disp(size(im))
    label = imread(fullfile(label_path,labels(i).name));
    masks = cell(1,length(cmap));
    for i = 1:length(masks)
        masks{i} = label == i;
    end
    imshow(im_with_overlays(im,masks,double(cmap)/256))
    
    
    drawnow
end

%classes of interest
config.labels(25) % Lane markings general (label id 24)
config.labels(14) % ROAD (label id 13) 
config.labels(3) %curb (label id 2)
config.labels(16) % sidewalk