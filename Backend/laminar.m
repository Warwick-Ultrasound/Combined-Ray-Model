function v = laminar(r, R, v_ave, ~)
    if r <= R 
        v = 2*v_ave*(1-r.^2/R^2);
    else 
        v = 0/0;
    end
end