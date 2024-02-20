function v = laminar(r, R, v_ave, ~)
    v = 2*v_ave*(1-r.^2/R^2);
    v(r>R) = 0/0;
end