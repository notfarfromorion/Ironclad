include "RefinementConvolution.i.dfy"
include "System.i.dfy"
include "SpecRefinement.i.dfy"
include "../Common/Collections/Maps.i.dfy"

module SystemRefinementModule {

    import opened RefinementConvolutionModule
    import opened SystemModule
    import opened SpecRefinementModule
    import opened Collections__Maps_i

    predicate SystemCorrespondence(ls:SystemState, hs:SystemState)
    {
        forall ss {:trigger SpecCorrespondence(ls, ss)}{:trigger SpecCorrespondence(hs, ss)} ::
              SpecCorrespondence(hs, ss) ==> SpecCorrespondence(ls, ss)
    }

    function GetSystemSystemRefinementRelation() : RefinementRelation<SystemState, SystemState>
    {
        iset pair:RefinementPair<SystemState, SystemState> {:trigger SystemCorrespondence(pair.low, pair.high)} |
             SystemCorrespondence(pair.low, pair.high)
    }

    predicate SystemBehaviorRefinesSystemBehavior(lb:seq<SystemState>, hb:seq<SystemState>)
    {
        BehaviorRefinesBehavior(lb, hb, GetSystemSystemRefinementRelation())
    }

    predicate SystemBehaviorRefinesSpecBehavior(lb:seq<SystemState>, hb:seq<SpecState>)
    {
        BehaviorRefinesBehavior(lb, hb, GetSystemSpecRefinementRelation())
    }

    lemma lemma_SystemRefinementRelationConvolvesWithItself()
        ensures RefinementRelationsConvolve(GetSystemSystemRefinementRelation(),
                                            GetSystemSystemRefinementRelation(),
                                            GetSystemSystemRefinementRelation());
    {
        var r := GetSystemSystemRefinementRelation();
        forall l, m, h | RefinementPair(l, m) in r && RefinementPair(m, h) in r
            ensures RefinementPair(l, h) in r;
        {
            forall ss | SpecCorrespondence(h, ss)
                ensures SpecCorrespondence(l, ss);
            {
                assert SpecCorrespondence(m, ss);
            }
            assert SystemCorrespondence(l, h);
        }
    }

    lemma lemma_SystemRefinementRelationConvolvesWithSpecRefinementRelation()
        ensures RefinementRelationsConvolve(GetSystemSystemRefinementRelation(),
                                            GetSystemSpecRefinementRelation(),
                                            GetSystemSpecRefinementRelation());
    {
        var r1 := GetSystemSystemRefinementRelation();
        var r2 := GetSystemSpecRefinementRelation();
        forall l, m, h | RefinementPair(l, m) in r1 && RefinementPair(m, h) in r2
            ensures RefinementPair(l, h) in r2;
        {
            assert SystemCorrespondence(l, m);
            assert SpecCorrespondence(m, h);
            assert SpecCorrespondence(l, h);
        }
    }

    lemma lemma_SystemSystemRefinementConvolution(
        lb:seq<SystemState>,
        mb:seq<SystemState>,
        hb:seq<SystemState>,
        lm_map:RefinementMap,
        mh_map:RefinementMap
        ) returns (
        lh_map:RefinementMap
        )
        requires BehaviorRefinesBehaviorUsingRefinementMap(lb, mb, GetSystemSystemRefinementRelation(), lm_map);
        requires BehaviorRefinesBehaviorUsingRefinementMap(mb, hb, GetSystemSystemRefinementRelation(), mh_map);
        ensures  BehaviorRefinesBehaviorUsingRefinementMap(lb, hb, GetSystemSystemRefinementRelation(), lh_map);
    {
        var relation := GetSystemSystemRefinementRelation();
        lemma_SystemRefinementRelationConvolvesWithItself();
        lh_map := lemma_RefinementConvolution(lb, mb, hb, relation, relation, relation, lm_map, mh_map);
    }

    lemma lemma_SystemSystemRefinementConvolutionPure(
        lb:seq<SystemState>,
        mb:seq<SystemState>,
        hb:seq<SystemState>
        )
        requires SystemBehaviorRefinesSystemBehavior(lb, mb);
        requires SystemBehaviorRefinesSystemBehavior(mb, hb);
        ensures  SystemBehaviorRefinesSystemBehavior(lb, hb);
    {
        var relation := GetSystemSystemRefinementRelation();
        lemma_SystemRefinementRelationConvolvesWithItself();
        lemma_RefinementConvolutionPure(lb, mb, hb, relation, relation, relation);
    }

    lemma lemma_SystemSpecRefinementConvolution(
        lb:seq<SystemState>,
        mb:seq<SystemState>,
        hb:seq<SpecState>,
        lm_map:RefinementMap,
        mh_map:RefinementMap
        ) returns (
        lh_map:RefinementMap
        )
        requires BehaviorRefinesBehaviorUsingRefinementMap(lb, mb, GetSystemSystemRefinementRelation(), lm_map);
        requires BehaviorRefinesBehaviorUsingRefinementMap(mb, hb, GetSystemSpecRefinementRelation(), mh_map);
        ensures  BehaviorRefinesBehaviorUsingRefinementMap(lb, hb, GetSystemSpecRefinementRelation(), lh_map);
    {
        var r1 := GetSystemSystemRefinementRelation();
        var r2 := GetSystemSpecRefinementRelation();
        lemma_SystemRefinementRelationConvolvesWithSpecRefinementRelation();
        lh_map := lemma_RefinementConvolution(lb, mb, hb, r1, r2, r2, lm_map, mh_map);
    }

    lemma lemma_SystemSpecRefinementConvolutionPure(
        lb:seq<SystemState>,
        mb:seq<SystemState>,
        hb:seq<SpecState>
        )
        requires SystemBehaviorRefinesSystemBehavior(lb, mb);
        requires SystemBehaviorRefinesSpecBehavior(mb, hb);
        ensures  SystemBehaviorRefinesSpecBehavior(lb, hb);
    {
        var r1 := GetSystemSystemRefinementRelation();
        var r2 := GetSystemSpecRefinementRelation();
        lemma_SystemRefinementRelationConvolvesWithSpecRefinementRelation();
        lemma_RefinementConvolutionPure(lb, mb, hb, r1, r2, r2);
    }

    lemma lemma_SystemValidSpecRefinementConvolutionPure(
        lb:seq<SystemState>,
        mb:seq<SystemState>,
        hb:seq<SpecState>
        )
        requires SystemBehaviorRefinesSystemBehavior(lb, mb);
        requires SystemBehaviorRefinesValidSpecBehavior(mb, hb);
        ensures  SystemBehaviorRefinesValidSpecBehavior(lb, hb);
    {
        lemma_SystemSpecRefinementConvolutionPure(lb, mb, hb);
        var lh_map :| SystemBehaviorRefinesValidSpecBehaviorUsingRefinementMap(lb, hb, lh_map);
    }

    lemma lemma_SystemSpecRefinementConvolutionExtraPure(
        lb:seq<SystemState>,
        mb:seq<SystemState>
        )
        requires SystemBehaviorRefinesSystemBehavior(lb, mb);
        requires SystemBehaviorRefinesSpec(mb);
        ensures  SystemBehaviorRefinesSpec(lb);
    {
        var hb, mh_map :| SystemBehaviorRefinesValidSpecBehaviorUsingRefinementMap(mb, hb, mh_map);
        lemma_SystemValidSpecRefinementConvolutionPure(lb, mb, hb);
    }

    lemma lemma_SystemStateCorrespondsToItself(ls:SystemState)
        ensures  SystemCorrespondence(ls, ls);
    {
        assert forall ss :: SpecCorrespondence(ls, ss) ==> SpecCorrespondence(ls, ss);
    }

    lemma lemma_SystemBehaviorRefinesItself(lb:seq<SystemState>)
        ensures  SystemBehaviorRefinesSystemBehavior(lb, lb);
    {
        var relation := GetSystemSystemRefinementRelation();
        var lh_map := ConvertMapToSeq(|lb|, map i | 0 <= i < |lb| :: RefinementRange(i, i));

        forall i, j {:trigger RefinementPair(lb[i], lb[j])} | 0 <= i < |lb| && lh_map[i].first <= j <= lh_map[i].last
            ensures RefinementPair(lb[i], lb[j]) in relation;
        {
            assert i == j;
            lemma_SystemStateCorrespondsToItself(lb[i]);
        }
        assert BehaviorRefinesBehaviorUsingRefinementMap(lb, lb, relation, lh_map);
    }

    lemma lemma_SystemCorrespondenceBetweenSystemStatesDifferingOnlyInTrackedActorStates(
        ls:SystemState,
        hs:SystemState
        )
        requires hs == ls.(states := hs.states);
        requires forall actor :: actor !in ls.config.tracked_actors ==> ActorStateMatchesInSystemStates(ls, hs, actor);
        ensures  SystemCorrespondence(ls, hs);
    {
        forall ss | SpecCorrespondence(hs, ss)
            ensures SpecCorrespondence(ls, ss);
        {
            lemma_TrackedActorStateDoesntAffectSpecCorrespondence(ls, hs, ss);
        }
    }

    lemma lemma_SystemCorrespondenceBetweenSystemBehaviorsDifferingOnlyInActorStates(
        lb:seq<SystemState>,
        hb:seq<SystemState>
        )
        requires |lb| == |hb|;
        requires forall i :: 0 <= i < |hb| ==> hb[i] == lb[i].(states := hb[i].states);
        requires forall i, actor :: 0 <= i < |hb| && actor !in lb[i].config.tracked_actors ==> ActorStateMatchesInSystemStates(lb[i], hb[i], actor);
        ensures  SystemBehaviorRefinesSystemBehavior(lb, hb);
    {
        var relation := GetSystemSystemRefinementRelation();
        var lh_map := ConvertMapToSeq(|lb|, map i | 0 <= i < |lb| :: RefinementRange(i, i));

        forall i, j {:trigger RefinementPair(lb[i], hb[j]) in relation} |
            0 <= i < |lb| && lh_map[i].first <= j <= lh_map[i].last
            ensures RefinementPair(lb[i], hb[j]) in relation;
        {
            lemma_SystemCorrespondenceBetweenSystemStatesDifferingOnlyInTrackedActorStates(lb[i], hb[j]);
        }
        
        assert BehaviorRefinesBehaviorUsingRefinementMap(lb, hb, relation, lh_map);
    }
}
