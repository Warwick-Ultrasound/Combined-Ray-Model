function ang = getAngle(ray)
    % Handy function for calculating the incident angle of a ray from the
    % equation
    dy = abs(ray.eq(2) - ray.eq(1));
    dx = 2-1;
    ang = 90 - atand(dy/dx);
end