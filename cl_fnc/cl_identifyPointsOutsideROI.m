function isOutsideROI = cl_identifyPointsOutsideROI(imageData, points, roiType)
    % cl_identifyPointsOutsideROI: Allows user to draw an ROI and identifies points
    % outside the drawn ROI.
    %
    % Inputs:
    %   - imageData: The input image (grayscale or RGB).
    %   - points: N x 2 array of point coordinates (x, y).
    %   - roiType: (Optional) Type of ROI to draw ('Circle', 'Ellipse', 'Freehand').
    %              Default is 'Freehand'.
    %
    % Outputs:
    %   - isOutsideROI: Logical vector of length N. True for points outside the ROI.

    % Input validation using arguments block (requires MATLAB R2020b or later)
    arguments
        imageData (:,:) {mustBeNumeric, mustBeNonempty}
        points (:,2) {mustBeNumeric, mustBeNonempty}
        roiType (1,:) char {mustBeMember(roiType, {'Circle', 'Ellipse', 'Freehand'})} = 'Freehand'
    end

    isOutsideROI = false(size(points,1));

    % Display the image
    figure;
    imshow(imageData, []);
    hold on;
    scatter(points(:, 1), points(:, 2), 20, 'r', 'filled'); % Overlay points
    title('Draw an ROI to select points');
    subtitle('Type "Enter" when done or close the window to cancel')
    
    % Draw the selected type of ROI
    switch roiType
        case 'Circle'
            roi = drawcircle();
        case 'Ellipse'
            roi = drawellipse();
        case 'Freehand'
            roi = drawfreehand();
    end

    % Wait until ROI drawing is complete
    try
        wait(roi);
    catch
        return
    end
    
    % Create a binary mask of the ROI
    roiMask = createMask(roi);
    
    % Check which points are inside the ROI
    x = points(:, 1); % X-coordinates of points
    y = points(:, 2); % Y-coordinates of points

    % Ensure coordinates are within bounds of the image
    x = max(min(round(x), size(roiMask, 2)), 1);
    y = max(min(round(y), size(roiMask, 1)), 1);

    % Identify points inside the ROI
    isInsideROI = arrayfun(@(i) roiMask(y(i), x(i)), 1:length(x));

    % Logical vector indicating points outside the ROI
    isOutsideROI = ~isInsideROI;

    % Visualize points outside the ROI
    scatter(points(isOutsideROI, 1), points(isOutsideROI, 2), 20, 'b', 'filled');
    legend('Original Points', 'Points Outside ROI', 'Location', 'best');

    % Display message with results
    disp(['Number of points outside ROI: ', num2str(sum(isOutsideROI))]);
end
