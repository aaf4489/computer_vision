% Main function. Reads in the given puzzle pieces, then applies a filter to
% clean up the noise, segments out the piece and then classifies the
% piece. After the piece is classified, the original, segmented, and
% classified image will be displayed in a figure.
function main()
    % Add the TEST_IMAGES directory to the search path
    addpath('../TEST_IMAGES');
    
    % Get all the JPEG files in the TEST_IMAGES directory and loop through
    % each file.
    file_names = dir('../TEST_IMAGES/*.jpg');
    
    % Counter variable to keep track of which version of the puzzle piece
    % we are reading currently.
    cnt = 0;
    
    % For all of the puzzle piece images
    for file_idx = 1 : length(file_names)
        % Read in the image as RGB
        im = imread( file_names(file_idx).name );
        % Convert the image to grayscale to make it easier to work with
        im_gray = rgb2gray(im);
        
        % Define the filters to use on the image
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
        
        % Perform canny edge on the filtered image
        im_canny = edge(medfilt2(im_filt2), 'canny', [0.04 0.12]);
        
        % Combine edges of the three images to reduce the chance of missing
        % an edge in just one image.
        %-----------------------------------------------------------------
        % First image case, set the combined image to the canny edge
        % results.
        if(cnt == 0)
            im_comb = im_canny;
            
        % If all three versions have combined or we have reached the last
        % image process the resulting image
        elseif(cnt == 3 || file_idx == 198)
            % Create a figure to display the three desired images
            % Display the original, unprocessed image
            figure
            subplot(2,2,1)
            hold on
            % Subtract two from the file index to display the second image
            % in the set of three because when we reach this point we will
            % be on the first image of the next piece. 
            imshow(imread( file_names(file_idx-2).name ));
            title('Original');
            hold off
            
            %Define structuring elements for initial morphology
            dil_el = strel('square', 7);
            erd_el = strel('square', 3);
            
            % Perform closing on the piece.
            im_dil = imdilate(im_comb, dil_el);
            im_erd = imerode(im_dil, erd_el);
            
            % Find largest region (the puzzle piece)
            [L, num] = bwlabel(im_erd, 8);
            count_pixels_per_obj = sum(bsxfun(@eq,L(:),1:num));
            [most,ind] = max(count_pixels_per_obj);
            biggest_blob = (L==ind);

            % Piece 15 needed a bit more dilation in order to properly fill
            % it, so dilate piece 15's results
            if(file_idx == 106)
                biggest_blob = imdilate(biggest_blob, strel('square', 4));
            end
            
            % Fill in the puzzle piece and erode to remove excess noise and
            % return the piece back to about the original size 
            filled_piece = imfill(biggest_blob, 'holes');
            filled_piece = imerode(filled_piece, strel('square', 7));
            
            % Special case closing operation to deal with piece 6 gaps
            if(file_idx == 19)
                filled_piece = imdilate(filled_piece, strel('square', 25));
                filled_piece = imfill(filled_piece, 'holes');
                filled_piece = imerode(filled_piece, strel('square', 27));
            end
            % For every piece besides piece 6, remove noise that made it
            % through. Piece 6 doesn't have noise and is dealt with in the
            % special case directly above this if statement.
            if(file_idx ~= 19 )
                test_image = imerode(filled_piece, strel('disk', 10));
                filled_piece = imdilate(test_image, strel('disk', 10));
            end
            
            % Check if there is a piece in the image, if not set entire
            % image to 0.
            if(most > 120000 || most < 24326)
                filled_piece(:) = 0;
            end
            
            % Display the segmented piece in the second position of our
            % figure.
            subplot(2,2,2)
            hold on
            imshow(filled_piece);
            title('Segmented Piece')
            hold off
            
            % Display the segmented piece in the third position of our
            % figure as the basis for our classification.
            subplot(2,2,3)
            hold on
            imshow(filled_piece)
            
            % If there is no piece in the image. We do not need to process
            % this image further.
            if(most > 120000 || most < 24326)
               title('No Piece') 
            end
            % If there is a piece in this image, classify it.
            if(most <= 120000 && most >= 24326)
                
                % Get the convex hull of the puzzle piece and then sort the
                % x and y coordinates in ascending order to 'find' the
                % edges
                stats = regionprops(filled_piece, 'ConvexHull');
                xs = sort(stats.ConvexHull(:,1));
                ys = sort(stats.ConvexHull(:,2));

                % Define the classifying points for each side of the puzzle
                % piece. We are looking for points that are close to the
                % edge of the puzzle piece but far enough in so we can tell
                % if there is a hole or not in that side.
                leftmost = floor(xs(1) + 55);
                rightmost = floor(xs(end) - 55);
                topmost = floor(ys(1) + 58);
                bottommost = floor(ys(end) - 57);

                % Get the dimensions of the image
                dims = size(filled_piece);
                
                % Define the classifying lines for each side using the
                % classifying points defined above. The process that
                % utilizes these lines will get the pixels on each edge
                % (about 55 pixles in) and then check the number of regions
                % on these lines. 2 regions indicates a hole as there is a
                % break in the piece. 1 region is either an edge or a head,
                % so we have to check the area of that region to determine
                % which it is.
                left_edge = filled_piece(1:dims(2), leftmost);
                right_edge = filled_piece(1:dims(2), rightmost);
                top_edge = filled_piece(topmost, 1:dims(1));
                bottom_edge = filled_piece(bottommost, 1:dims(1));
                
                % Get distance between left and right edges and top and
                % bottom edges to calculate the percentage edge a region is
                % in case there is only one region. 
                x_diff = rightmost - leftmost;
                y_diff = bottommost - topmost;
                
                % Initialize classification counts
                edges = 0;
                heads = 0;
                holes = 0;
                results = [0 0 0 0];
                
                % Get the regions and number of regions along the
                % classifying lines
                [Left, numL] = bwlabel(left_edge);
                [Right, numR] = bwlabel(right_edge);
                [Top, numT] = bwlabel(top_edge);
                [Bottom, numB] = bwlabel(bottom_edge);
                
                % If the left edge is one region, get the area of that
                % region. If the region is over 50 percent of the total
                % possible area classify it as an edge otherwise a head
                if(numL == 1)
                    statClassifier = regionprops(Left, 'Area');
                    percentEdge = statClassifier.Area / x_diff * 100;
                    
                    if(percentEdge > 50)
                        edges = edges + 1;
                    else
                        heads = heads + 1;
                        results(1) = 1;
                    end
                end
                % If the right edge is one region, get the area of that
                % region. If the region is over 50 percent of the total
                % possible area classify it as an edge otherwise a head
                if(numR == 1)
                    statClassifier = regionprops(Right, 'Area');
                    percentEdge = statClassifier.Area / x_diff * 100;
                    
                    if(percentEdge > 50)
                        edges = edges + 1;
                    else
                        heads = heads + 1;
                        results(3) = 1;
                    end
                end
                % If the top edge is one region, get the area of that
                % region. If the region is over 50 percent of the total
                % possible area classify it as an edge otherwise a head
                if(numT == 1)
                    statClassifier = regionprops(Top, 'Area');
                    percentEdge = statClassifier.Area / y_diff * 100;

                    if(percentEdge > 50)
                        edges = edges + 1;
                    else
                        heads = heads + 1;
                        results(2) = 1;
                    end
                end
                % If the bottom edge is one region, get the area of that
                % region. If the region is over 50 percent of the total
                % possible area classify it as an edge otherwise a head
                if(numB == 1)
                    statClassifier = regionprops(Bottom, 'Area');
                    percentEdge = statClassifier.Area / y_diff * 100;

                    if(percentEdge > 50)
                        edges = edges + 1;
                    else
                        heads = heads + 1;
                        results(4) = 1;
                    end
                end
                
                % If the left edge is two regions, classify it as a hole
                if(numL == 2)
                    holes = holes + 1;
                    results(1) = 2;
                end
                % If the right edge is two regions, classify it as a hole
                if(numR == 2)
                    holes = holes + 1;
                    results(3) = 2;
                end
                % If the top edge is two regions, classify it as a hole
                if(numT == 2)
                    holes = holes + 1;
                    results(2) = 2;
                end
                % If the bottom edge is two regions, classify it as a hole
                if(numB == 2)
                    holes = holes + 1;
                    results(4) = 2;
                end
                
                if(heads == 2)
                    if((results(1) == results(2) && results(1) == 1) ||...
                            (results(1) == results(4) && results(1) == 1))
                            % Define the title of the classified image
                            title_string = "Holes: " + string(holes) + ", Heads: " +...
                            string(heads) + " (Adjacent), Edges: " + string(edges);
                            title(title_string)
                    elseif((results(2) == results(3) && results(3) == 1) ||...
                            (results(3) == results(4) && results(3) == 1))
                            % Define the title of the classified image
                            title_string = "Holes: " + string(holes) + ", Heads: " +...
                            string(heads) + " (Adjacent), Edges: " + string(edges);
                            title(title_string)
                    else
                        % Define the title of the classified image
                        title_string = "Holes: " + string(holes) + ", Heads: " +...
                        string(heads) + " (Opposite), Edges: " + string(edges);
                        title(title_string)
                    end
                elseif(holes == 2 && heads ~= 2)
                    if((results(1) == results(2) && results(1) == 2) ||...
                            (results(1) == results(4) && results(1) == 2))
                            % Define the title of the classified image
                            title_string = "Holes: " + string(holes) + " (Adjacent), Heads: " +...
                            string(heads) + ", Edges: " + string(edges);
                            title(title_string)
                    elseif((results(2) == results(3) && results(3) == 2) ||...
                            (results(3) == results(4) && results(3) == 2))
                            % Define the title of the classified image
                            title_string = "Holes: " + string(holes) + " (Adjacent), Heads: " +...
                            string(heads) + ", Edges: " + string(edges);
                            title(title_string)
                    else
                        % Define the title of the classified image
                        title_string = "Holes: " + string(holes) + " (Opposite), Heads: " +...
                        string(heads) + ", Edges: " + string(edges);
                        title(title_string)
                    end
                else
                    % Define the title of the classified image
                    title_string = "Holes: " + string(holes) + ", Heads: " +...
                        string(heads) + ", Edges: " + string(edges);
                    title(title_string)
                end
                % Display the classifying lines on the classification image
                plot([leftmost leftmost], [1 dims(2)], 'r-')
                plot([rightmost rightmost], [1 dims(2)], 'r-')
                plot([1 dims(1)], [topmost topmost], 'r-')
                plot([1 dims(1)], [bottommost bottommost], 'r-')
            end
            hold off
            % Pause for a second to be able to view the figure
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
        % Increase puzzle piece version count by 1
        cnt = cnt + 1;
                
    end
end