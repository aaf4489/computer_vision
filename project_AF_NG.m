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

            if(file_idx == 106)
                biggest_blob = imdilate(biggest_blob, strel('square', 4));
            end
            % Fill in the puzzle piece and erode to remove excess noise and
            % return the piece back to about the original size 
            filled_piece = imfill(biggest_blob, 'holes');
            filled_piece = imerode(filled_piece, strel('square', 7));
            % Check if there is a piece in the image
            if(file_idx == 19)
                filled_piece = imdilate(filled_piece, strel('square', 25));
                filled_piece = imfill(filled_piece, 'holes');
                filled_piece = imerode(filled_piece, strel('square', 27));
            end
            if(file_idx ~= 19 )
                test_image = imerode(filled_piece, strel('disk', 10));
                filled_piece = imdilate(test_image, strel('disk', 10));
            end
            if(most > 120000 || most < 24326)
                filled_piece(:) = 0;
            end
            
            figure 
            imshow(filled_piece);
            hold on
            if(most > 120000 || most < 24326)
               title('No Piece') 
            end 
            if(most <= 120000 && most >= 24326)
                
                stats = regionprops(filled_piece, 'ConvexHull');
                xs = sort(stats.ConvexHull(:,1));
                ys = sort(stats.ConvexHull(:,2));

                leftmost = floor(xs(1) + 55);
                rightmost = floor(xs(end) - 55);

                topmost = floor(ys(1) + 58);
                bottommost = floor(ys(end) - 57);

                dims = size(filled_piece);
                
                left_edge = filled_piece(1:dims(2), leftmost);
                right_edge = filled_piece(1:dims(2), rightmost);
                top_edge = filled_piece(topmost, 1:dims(1));
                bottom_edge = filled_piece(bottommost, 1:dims(1));
                
                x_diff = rightmost - leftmost;
                y_diff = bottommost - topmost;
                
                edges = 0;
                heads = 0;
                holes = 0;
                
                [Left, numL] = bwlabel(left_edge);
                [Right, numR] = bwlabel(right_edge);
                [Top, numT] = bwlabel(top_edge);
                [Bottom, numB] = bwlabel(bottom_edge);
                
                if(numL == 1)
                    statClassifier = regionprops(Left, 'Area');
                    percentEdge = statClassifier.Area / x_diff * 100;
                    
                    if(percentEdge > 50)
                        edges = edges + 1;
                    else
                        heads = heads + 1;
                    end
                end
                if(numR == 1)
                    statClassifier = regionprops(Right, 'Area');
                    percentEdge = statClassifier.Area / x_diff * 100;
                    
                    if(percentEdge > 50)
                        edges = edges + 1;
                    else
                        heads = heads + 1;
                    end
                end
                if(numT == 1)
                    statClassifier = regionprops(Top, 'Area');
                    percentEdge = statClassifier.Area / y_diff * 100;

                    if(percentEdge > 50)
                        edges = edges + 1;
                    else
                        heads = heads + 1;
                    end
                end
                if(numB == 1)
                    statClassifier = regionprops(Bottom, 'Area');
                    percentEdge = statClassifier.Area / y_diff * 100;

                    if(percentEdge > 50)
                        edges = edges + 1;
                    else
                        heads = heads + 1;
                    end
                end
                
                if(numL == 2)
                    holes = holes + 1;
                end
                if(numR == 2)
                    holes = holes + 1;
                end
                if(numT == 2)
                    holes = holes + 1;
                end
                if(numB == 2)
                    holes = holes + 1;
                end
                
                title_string = "Holes: " + string(holes) + ", Heads: " + string(heads) + ", Edges: " + string(edges);
                title(title_string)
                plot([leftmost leftmost], [1 dims(2)], 'r-')
                plot([rightmost rightmost], [1 dims(2)], 'r-')
                plot([1 dims(1)], [topmost topmost], 'r-')
                plot([1 dims(1)], [bottommost bottommost], 'r-')
            end
            pause(2);
            
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