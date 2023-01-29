function detect_figures(im)
    gray = rgb2gray(im);
    figure, imshow(gray)
    m_bin = gray;
    figure, imshow(m_bin)
    %get stats
    stats =  regionprops(m_bin,'Centroid', 'Circularity','MajorAxisLength','MinorAxisLength','Area');
    Centroid = cat(1, stats.Centroid);
    Area = cat(1,stats.Area);
    Ratio = cat(1,stats.MajorAxisLength) - cat(1,stats.MinorAxisLength);

    CircleMetric = cat(1,stats.Circularity);  %circularity metric
    SquareMetric = Ratio;
    TriangleMetric = NaN(length(CircleMetric),1);

    boxArea = m_minbbarea(m_bin);

    %for each boundary, fit to bounding box, and calculate some parameters
    for k=1:length(TriangleMetric),
        TriangleMetric(k) = Area(k)/boxArea(k);  %filled area vs box area
    end
    %define some thresholds for each metric
    %do in order of circle, triangle, square, rectangle to avoid assigning the
    %same shape to multiple objects
    isCircle =   (CircleMetric > 0.95);
    isTriangle = ~isCircle & (TriangleMetric < 0.65);
    isSquare =   ~isCircle & ~isTriangle & (SquareMetric < 1) & (TriangleMetric > 0.9);
    isRectangle= ~isCircle & ~isTriangle & ~isSquare & (TriangleMetric > 0.9);
    isPentagono= ~isCircle & ~isTriangle & ~isSquare & ~isRectangle;%isn't any of these
    %assign shape to each object
    whichShape = cell(length(TriangleMetric),1);
    whichShape(isCircle) = {'Circle'};
    whichShape(isTriangle) = {'Triangle'};
    whichShape(isSquare) = {'Square'};
    whichShape(isRectangle)= {'Rectangle'};
    whichShape(isPentagono)= {'Pentagono/hexagono'};
    %now label with results
    RGB = label2rgb(bwlabel(m_bin));
    figure, imshow(RGB); hold on;
    pause(1)
    Combined = [CircleMetric, SquareMetric, TriangleMetric];
    for k=1:length(TriangleMetric),
        %display metric values and which shape next to object
        Txt = sprintf('C=%0.3f S=%0.3f T=%0.3f',  Combined(k,:));
        text( Centroid(k,1)-20, Centroid(k,2), Txt);
        text( Centroid(k,1)-20, Centroid(k,2)+20, whichShape{k});
    end
end


