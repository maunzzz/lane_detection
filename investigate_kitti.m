im_f = '/media/cvia/disk2/Data/lane_detection/data_road/training/image_2';
gt_f = '/media/cvia/disk2/Data/lane_detection/data_road/training/gt_image_2';

ims = dir(fullfile(im_f,'um_*.png'));
gts = dir(fullfile(gt_f,'um_*.png'));

f = figure;
for i = 1:length(ims)
    set(0,'currentfigure',f)
    
    im = imread(fullfile(im_f,ims(i).name));
    tmp1 = imread(fullfile(gt_f,[ims(i).name(1:3) 'lane_' ims(i).name(4:end)]));
    tmp2 = imread(fullfile(gt_f,[ims(i).name(1:3) 'road_' ims(i).name(4:end)]));
    
    tmp1 = double(tmp1);
    tmp1 = sum(tmp1,3);

    tmp2 = double(tmp2);
    tmp2 = sum(tmp2,3);
    
    gt = 2*(tmp2 > 300) + 3*(tmp2<200);
    gt(tmp1 > 300) = 1;
    imshow(im_with_overlays(im,{gt == 0, gt == 1, gt == 2, gt == 3}));
    
%     subplot(3,1,1);imshow(im);
%     subplot(3,1,2);imshow(tmp1);
%     subplot(3,1,3);imshow(tmp2);
    asd = 0;
end