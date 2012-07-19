module pico_camb


    use CAMBmain, only : InitVars
    use ModelParams, only : CAMBparams, CAMBParams_Set, CosmomcTheta, lmin
    use ModelData, only : cl_scalar, cl_lensed, cl_tensor
    use Transfer, only : MT, transfer_tot, transfer_kh, transfer_allocate, transfer_get_sigma8
    use CAMB, only : w_lam, CAMB_GetResults, C_Temp, C_E, C_last, C_Cross, CT_E, CT_B, CT_Temp, CT_Cross, CT_B
    use InitialPower, only : InitializePowers

    implicit none

contains

    subroutine Pico_GetResults(P, error, used_pico)

        type(CAMBparams) :: P
        integer, optional, intent(out) :: error !Zero if OK
        logical, optional, intent(out) :: used_pico
        integer(4) :: n_q_trans, dum
        real(8), dimension(:), allocatable :: tmp_trans
        real(8) :: fac
        logical :: success

        call CAMBParams_Set(P)

        call fpico_reset_params()
        call fpico_set_param("ombh2", p%omegab*(p%H0/100.)**2)
        call fpico_set_param("omch2", p%omegac*(p%H0/100.)**2)
        call fpico_set_param("omnuh2", p%omegan*(p%H0/100.)**2)
        call fpico_set_param("omvh2", p%omegav*(p%H0/100.)**2)
        call fpico_set_param("omk", p%omegak)
        call fpico_set_param("hubble", p%H0)
        call fpico_set_param("w", real(w_lam,8))
        call fpico_set_param("theta", CosmomcTheta())
        call fpico_set_param("helium_fraction", p%yhe)
        call fpico_set_param("massless_neutrinos", p%Num_Nu_massless)
        call fpico_set_param("massive_neutrinos", real(p%Num_Nu_massive,8))
        call fpico_set_param("scalar_spectral_index(1)",p%InitPower%an(1))
        call fpico_set_param("tensor_spectral_index(1)",p%InitPower%ant(1))
        call fpico_set_param("scalar_nrun(1)",p%InitPower%n_run(1))
        call fpico_set_param("initial_ratio(1)",p%InitPower%rat(1))
        call fpico_set_param("scalar_amp(1)",p%InitPower%ScalarPowerAmp(1))
        call fpico_set_param("pivot_scalar",p%InitPower%k_0_scalar)
        call fpico_set_param("re_optical_depth",p%Reion%optical_depth)


        call fpico_reset_requested_outputs()
        if (P%WantCls) then
            if (P%WantScalars) then
                call fpico_request_output("scalar_TT")
                call fpico_request_output("scalar_TE")
                call fpico_request_output("scalar_EE")
            end if
            if (P%WantTensors) then
                call fpico_request_output("tensor_TT")
                call fpico_request_output("tensor_TE")
                call fpico_request_output("tensor_EE")
                call fpico_request_output("tensor_BB")
            end if
            if (P%DoLensing) then
                call fpico_request_output("lensed_TT")
                call fpico_request_output("lensed_TE")
                call fpico_request_output("lensed_EE")
                call fpico_request_output("lensed_BB")
            end if
            if (P%WantTransfer) then
                call fpico_request_output("k")
                call fpico_request_output("pk")
            end if
        end if


        call fpico_compute_result(success)


        if (success) then

            call InitVars

            if (P%WantCls) then
                if (allocated(Cl_scalar)) deallocate(Cl_scalar)
                if (allocated(Cl_tensor)) deallocate(Cl_tensor)
                if (allocated(Cl_lensed)) deallocate(Cl_lensed)
                allocate(Cl_scalar(lmin:P%Max_l,1,C_Temp:C_last))
                allocate(Cl_tensor(lmin:P%Max_l_tensor,1,CT_Temp:CT_Cross))
                allocate(Cl_lensed(lmin:P%Max_l,1,CT_Temp:CT_Cross))

                fac = P%tcmb**(-2) * 1e-12

                if (P%WantScalars) then
                    call fpico_read_output("scalar_TT",Cl_scalar(:,1,C_Temp),lmin,P%Max_l)
                    call fpico_read_output("scalar_TE",Cl_scalar(:,1,C_Cross),lmin,P%Max_l)
                    call fpico_read_output("scalar_EE",Cl_scalar(:,1,C_E),lmin,P%Max_l)
                    Cl_scalar = Cl_scalar * fac
                end if

                if (P%WantTensors) then
                    call fpico_read_output("tensor_TT",Cl_tensor(:,1,CT_Temp),lmin,P%Max_l_tensor)
                    call fpico_read_output("tensor_TE",Cl_tensor(:,1,CT_Cross),lmin,P%Max_l_tensor)
                    call fpico_read_output("tensor_EE",Cl_tensor(:,1,CT_E),lmin,P%Max_l_tensor)
                    call fpico_read_output("tensor_BB",Cl_tensor(:,1,CT_B),lmin,P%Max_l_tensor)
                    Cl_tensor = Cl_tensor * fac
                end if

                if (P%DoLensing) then
                    call fpico_read_output("lensed_TT",Cl_lensed(:,1,CT_Temp),lmin,P%Max_l)
                    call fpico_read_output("lensed_TE",Cl_lensed(:,1,CT_Cross),lmin,P%Max_l)
                    call fpico_read_output("lensed_EE",Cl_lensed(:,1,CT_E),lmin,P%Max_l)
                    call fpico_read_output("lensed_BB",Cl_lensed(:,1,CT_B),lmin,P%Max_l)
                    Cl_lensed = Cl_lensed * fac
                end if

            end if

            if (P%WantTransfer) then
                call fpico_get_output_len("k",n_q_trans)
                n_q_trans = n_q_trans-1
                call InitializePowers(p%initpower,p%omegak)

                MT%num_q_trans = n_q_trans
                call Transfer_Allocate(MT)

                allocate(tmp_trans(n_q_trans))

                call fpico_read_output("k",tmp_trans,0,n_q_trans-1)
                MT%q_trans = tmp_trans
                MT%TransferData(Transfer_kh,:,1) = tmp_trans
                call fpico_read_output("pk",tmp_trans,0,n_q_trans-1)
                MT%TransferData(Transfer_tot,:,1) = tmp_trans
                deallocate(tmp_trans)

                call Transfer_Get_sigma8(MT,8._8)
            end if
        else
            call CAMB_GetResults(P,error)
        end if

        if (present(used_pico)) used_pico = success

    end subroutine

end module
