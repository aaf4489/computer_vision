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
    for file_idx = 1 : length(file_names)
        im = imread( file_names(file_idx).name );
        im_gray = rgb2gray(im);
        
        filt_dx = fspecial('average');
        filt_dy = filt_dx.';
        filt2_dx = fspecial('log');
        filt2_dy = filt2_dx.';
        
        im_filt_x = imfilter( im_gray, filt_dx );
        im_filt_y = imfilter( im_gray, filt_dy );

        im_filt = im_filt_x + im_filt_y;
        
        im_filt_x2 = imfilter( im_filt, filt2_dx );
        im_filt_y2 = imfilter( im_filt, filt2_dy );

        im_filt2 = im_filt_x2 + im_filt_y2;
        
        im_test = edge(im_filt2, 'canny', [0.05 0.3]);
        
        % Combine edges of the three images to reduce error and get more of
        % the edges that other images may miss. 
        if(cnt == 0)
            im_comb = im_test;
        elseif(cnt == 3)
            figure
            imshow(im_comb)
  
            im_comb = im_test;
            cnt = 0;
        else
            im_comb = im_comb + im_test;
        end
        
        cnt = cnt + 1;
    end
end
