% Main function. Reads in the pieces to match and calls all of the other
% functions.
function main()
    % Add the TEST_IMAGES directory to the search path
    addpath('../TEST_IMAGES');
    % Get all the JPEG files in the TEST_IMAGES directory and loop through
    % each file.
    file_names = dir('../TEST_IMAGES/*.jpg');
    %images = cell(3,66);
    cnt = 0;
    for file_idx = 1 : 21%length(file_names)
        im = imread( file_names(file_idx).name );
        im_gray = rgb2gray(im);
        
        % Define filters
        filt_dx = fspecial('average');
        filt_dy = filt_dx.';
        filt2_dx = fspecial('log');
        filt2_dy = filt2_dx.';
        
        % Apply the average filter to the horizontal and vertical
        % directions and then combine the results
        im_filt_x = imfilter( im_gray, filt_dx );
        im_filt_y = imfilter( im_gray, filt_dy );
        im_filt = im_filt_x + im_filt_y;
        
        % Apply a Laplacian of Gaussian filter to the averaged image in the
        % vertical and horizontal directions and then combine the results
        im_filt_x2 = imfilter( im_filt, filt2_dx );
        im_filt_y2 = imfilter( im_filt, filt2_dy );
        im_filt2 = im_filt_x2 + im_filt_y2;
        
        
        im_canny = edge(im_filt2, 'canny', [0.05 0.15]);
        
        % Combine edges of the three images to reduce error and get more of
        % the edges that other images may miss. 
        if(cnt == 0)
            im_comb = im_canny;
        elseif(cnt == 3)
            
            dil_el = strel('square', 7);
            erd_el = strel('square', 3);
            
            im_dil = imdilate(im_comb, dil_el);
            im_erd = imerode(im_dil, erd_el);
            
            [L, num] = bwlabel(im_erd, 8);
            count_pixels_per_obj = sum(bsxfun(@eq,L(:),1:num));
            [~,ind] = max(count_pixels_per_obj);
            biggest_blob = (L==ind);

            figure
            filled_piece = imfill(biggest_blob, 'holes');
            
            C = corner(filled_piece, 'harris', 4);
            imshow(filled_piece);
            hold on
            plot(C(:,1),C(:,2),'r*');
            pause(1);
  
            im_comb = im_canny;
            cnt = 0;
        else
            im_comb = im_comb + im_canny;
        end
        
        cnt = cnt + 1;
        
        
    end
end
