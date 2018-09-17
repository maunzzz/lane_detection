function create_lane_dataset()

data_set_path = '/media/lmans/Data/mapillary-vistas-dataset_public_v1.0';
save_path = '/media/lmans/Data/mapillary-for-lane-detection/lane-segs';
training_path = fullfile(data_set_path,'training');
im_path = fullfile(training_path,'images');
label_path = fullfile(training_path,'labels');

ims = dir(fullfile(im_path,'*.jpg'));
labels = dir(fullfile(label_path,'*.png'));

config = jsondecode(fileread(fullfile(data_set_path,'config.json')));
cmap = uint8([config.labels(:).color].');
figure;
for i = 1:length(ims)
    fprintf('image %d/%d -- ',i,length(ims));
    im = imread(fullfile(im_path,ims(i).name));
    label = imread(fullfile(label_path,labels(i).name));
    
    
    if include_image(label)
        mask2 = extraxt_lanes(label);
        
        subplot(1,3,1);imshow(im_with_overlays(im,{mask2}));
        subplot(1,3,2);imshow(label,cmap);
        subplot(1,3,3);imshow(im_with_overlays(im,{mask2,label == 24 | label == 2}));
        
        if sum(mask2(:))/sum(label(:) == 24 | label(:) == 2 | label(:) == 13) < 0.5
            fprintf(' INCLUDE \n');
            imwrite(mask2,fullfile(save_path,labels(i).name));
        else
            fprintf(' REMOVE \n');
        end
    else
        fprintf(' REMOVE \n');
        subplot(1,2,1);imshow(im);
        subplot(1,2,2);imshow(label,cmap);
    end
    
    drawnow
end

end

function huh = include_image(label)
sz = size(label);

lower_half = label(floor(sz(2)/2):end,:);

%figure;imshow(lower_half)

n_pixels = prod(sz/2);

frac_road = sum(lower_half(:) == 13)/n_pixels;
frac_lane_markers = sum(lower_half(:) == 24 | lower_half(:) == 2)/n_pixels;

fprintf('road: %f, lane markers %f -- ',frac_road,frac_lane_markers);
huh = frac_road > 0.3 & frac_lane_markers > 0.005;
end

function mask2return = extraxt_lanes(label)
sz = size(label);
y = 1:sz(1);

masknow = label == 24 | label == 2;
mask2return = false(sz);
sum_start = sum(masknow(:));
% figure;
while sum(masknow(:)) > 0.1*sum_start
    c = ransac_lane(label,masknow);
    
    if isnan(c)
        break;
    end
    x = round(c(1) + c(2)*y + c(3)*y.^2 + c(4)*y.^3);
    ok_inds = x >= 1 & x < sz(2);
    ok_lin_inds = sub2ind(sz,y(ok_inds),x(ok_inds));
    mask = false(sz);
    mask(ok_lin_inds) = true;
    mask = growmask_and_remove(mask, label);
    
    mask2return = mask2return | mask;
    masknow = masknow & ~imdilate(mask,strel('disk',19,8));
    
%     subplot(1,2,1);imshow(mask2return);
%     subplot(1,2,2);imshow(masknow);
%     
%     dx = mean(abs(c(2) + 2*c(3)*y(ok_inds) + 3*c(4)*y(ok_inds).^2));
%     d2x = mean(abs(2*c(3) + 6*c(4)*y(ok_inds)));
%     d3x = abs(6*c(4));
%     fprintf('dx: %e \t d2x: %e \t d3x: %e \t ok %d  \n',dx,d2x,d3x,sum(ok_inds));
%     drawnow;
end

end

function c_best = ransac_lane(label,mask)
n_it = 10000;
% 
% 
% mask = erode_mask(mask);

[y,x] = find(mask);
c_best = nan;
best_score = 0;

for it = 1:n_it
    inds = randperm(length(x),4);
    b = x(inds);
    A = [ones(size(y(inds))) , y(inds) , y(inds).^2 ,  y(inds).^3];
    %disp(rcond(A))
    if rcond(A) > 1e-15
        c = A\b; % calculate coordinates
        score = evaluate_c(label,c);
        if score > best_score
            best_score = score;
            c_best = c;
        end
    end
end

%fprintf('best score %f --',best_score);
end

function score = evaluate_c(label,c)
sz = size(label);
y = 1:sz(1);
x = round(c(1) + c(2)*y + c(3)*y.^2 + c(4)*y.^3);
ok_inds = x >= 1 & x < sz(2);
ok_lin_inds = sub2ind(sz,y(ok_inds),x(ok_inds));

d2x = mean(abs(2*c(3) + 6*c(4)*y(ok_inds)));
d3x = abs(6*c(4));
if d2x < 5e-2 && d3x < 2e-4 && sum(ok_inds) > sz(1)/8
    %disp(d2x)
    mask = false(sz);
    mask(ok_lin_inds) = true;
    mask2 = imdilate(mask,strel('disk',15,4));
    score = sum(mask2(:) & ((label(:) == 24) | (label(:) == 2)))/sum(mask2(:) & ((label(:) == 24) | (label(:) == 13) | (label(:) == 2)));
    
%     if score > 0.8
%         figure;
%         subplot(2,3,1);imshow(mask2);title('mask')
%         
%         subplot(2,3,2);imshow(mask2 & ((label == 24) | (label == 2)));title('overlap');
%         subplot(2,3,3);imshow(mask2 & ((label == 24) | (label == 13) | (label == 2)));title('all');
%         subplot(2,3,4);imshow((label == 24) |(label == 2));title('markers');
%         
%         drawnow
%     end
else
    
    score = 0;
end
end

function mask = growmask_and_remove(mask, labels)
mask = mask & (labels == 24 | labels == 13 | labels == 2); %remove any pixels not on road, curb or lane marker class

overlap_kminusone = sum(mask(:) & (labels(:) == 24 | labels(:) == 2));
mask = imdilate(mask,strel('disk',3,8));
overlap_k = sum(mask(:) & (labels(:) == 24 | labels(:) == 2) );
overlap_start_change = overlap_k - overlap_kminusone;
while(overlap_k - overlap_kminusone > 0.7*overlap_start_change)
    overlap_kminusone = overlap_k;
    mask = imdilate(mask,strel('disk',3,8));
    overlap_k = sum(mask(:) & (labels(:) == 24 | labels(:) == 2));
end
end

function mask = erode_mask(mask)
% figure;imshow(mask);
cc = bwconncomp(mask);
mask = false(size(mask));
% figure;
for i = 1:cc.NumObjects
    tmpmask = false(size(mask));
    tmpmask(cc.PixelIdxList{i}) = true;
    mask = mask | erode_part(tmpmask);
%     imshow(mask);
%     asd = 0;
end
% imshow(mask);
% asd = 0;
end

function mask = erode_part(mask)
% figure;
summask = sum(mask(:));
cc = bwconncomp(mask);
while sum(mask(:)) > 0.3 * summask || cc.NumObjects > 1
    mask_b4 = mask;
    mask = imerode(mask,ones(1,3));
%         subplot(1,2,1);imshow(mask_b4);
%         subplot(1,2,2);imshow(mask);
%         asd = 0;
        cc = bwconncomp(mask);
end
mask = mask_b4;
end