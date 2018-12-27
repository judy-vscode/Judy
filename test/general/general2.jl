
function getMin(arr)
#
  if length(arr) == 0
    return Nothing
  end

  min = arr[1] #
  for ele in arr
    if ele < min
      min = ele #
    end
  end

  return min
end