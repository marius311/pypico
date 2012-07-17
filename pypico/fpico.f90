module fpico

    interface
        function fpico_compute_result_()
            logical :: fpico_compute_result_
        end function
    end interface

end module

subroutine fpico_load(file)
    character(len=*) :: file
    print *, "Loading PICO..."
    call fpico_load_(file,len(file))
end subroutine

subroutine fpico_set_param(name,value)
    character(len=*) :: name
    real(8) :: value
    call fpico_set_param_(name,len(name),value)
end subroutine


subroutine fpico_compute_result(success)
    use fpico
    logical :: success_
    logical, optional :: success
    success_ = fpico_compute_result_()
    if (present(success)) success=success_
end subroutine

subroutine fpico_get_output_len(key, nresult)
    character(len=*) :: key
    integer(4) :: nresult
    call fpico_get_output_len_(key, len(key), nresult)
end subroutine

subroutine fpico_read_output(key, result, istart, iend)
    character(len=*) :: key
    real(8), dimension(istart:iend) :: result
    integer :: istart, iend
    call fpico_read_output_(key, len(key), result, istart, iend)
end subroutine


subroutine fpico_has_output(key,has_output)
    character(len=*) :: key
    logical :: has_output
    has_output = (fpico_has_output_(key,len(key)) == 0)
end subroutine

