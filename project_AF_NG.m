% Main function. Reads in the pieces to match and calls all of the other
% functions.
function main()
    % Add the TEST_IMAGES directory to the search path
    addpath('../TEST_IMAGES');
    % Get all the JPEG files in the TEST_IMAGES directory and loop through
    % each file.
    file_names = dir('../TEST_IMAGES/*.jpg');
    cnt = 0;
    for file_idx = 1 : length(file_names)
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
        
        % Perform canny edge
        im_canny = edge(medfilt2(im_filt2), 'canny', [0.04 0.12]);
        
        % Combine edges of the three images to reduce error and get more of
        % the edges that other images may miss. 
        if(cnt == 0)
            im_comb = im_canny;
        % Need or condition to display the last piece
        elseif(cnt == 3 || file_idx == 198)
            
            %Define structuring elements
            dil_el = strel('square', 7);
            erd_el = strel('square', 3);
            
            % Perform closing on piece
            im_dil = imdilate(im_comb, dil_el);
            im_erd = imerode(im_dil, erd_el);
            
            % Find largest region (the puzzle piece)
            [L, num] = bwlabel(im_erd, 8);
            count_pixels_per_obj = sum(bsxfun(@eq,L(:),1:num));
            [most,ind] = max(count_pixels_per_obj);
            biggest_blob = (L==ind);

            % Fill in the puzzle piece and erode to remove excess noise and
            % return the piece back to about the original size 
            filled_piece = imfill(biggest_blob, 'holes');
            filled_piece = imerode(filled_piece, strel('square', 7));
            
            % Check if there is a piece in the image
            if(most > 120000 || most < 24326)
                filled_piece(:) = 0;
            end
            
            %C = corner(filled_piece, 'harris', 4);
            figure
            imshow(filled_piece);
            %hold on
            %plot(C(:,1),C(:,2),'r*');
            pause(1);
            
            % Conditions for pieces that overlapped to ignore one of the
            % images
            if(file_idx ~= 103 && file_idx ~= 25)
               im_comb = im_canny;
            end
            cnt = 0;
        else
            % Extra conditions to take/ignore certain images in order to
            % get the best results for segmentation
            if(file_idx == 104 || file_idx == 27)
               im_comb = im_canny;
            end
            if(file_idx ~= 26 && file_idx ~= 32 && ...
                    file_idx ~= 33 && file_idx ~= 105)
               im_comb = im_comb + im_canny;
            end
        end
        
        cnt = cnt + 1;
        
        
    end
end